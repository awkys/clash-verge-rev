use std::{
    sync::atomic::{AtomicBool, Ordering},
    time::Duration,
};

use anyhow::Result;

use crate::{
    config::Config,
    core::{
        CoreManager, Timer,
        handle::Handle,
        hotkey::Hotkey,
        logger::Logger,
        service::{SERVICE_MANAGER, ServiceManager, is_service_ipc_path_exists},
        sysopt,
        tray::Tray,
    },
    feat,
    module::{auto_backup::AutoBackupManager, lightweight::auto_lightweight_boot},
    process::AsyncHandler,
    utils::{init, server, window_manager::WindowManager},
};
use clash_verge_logging::{Type, logging, logging_error};
use clash_verge_signal;

pub mod dns;
pub mod scheme;
pub mod ui;
pub mod window;
pub mod window_script;

static RESOLVE_DONE: AtomicBool = AtomicBool::new(false);
static STARTUP_SUBSCRIPTION_UPDATE_TRIGGERED: AtomicBool = AtomicBool::new(false);

pub fn init_work_dir_and_logger() -> anyhow::Result<()> {
    AsyncHandler::block_on(async {
        init_work_config().await;
        init_resources().await;
        logging!(info, Type::Setup, "Initializing logger");
        // #[cfg(not(feature = "tokio-trace"))]
        Logger::global().init().await?;
        Ok(())
    })
}

pub fn resolve_setup_sync() {
    AsyncHandler::spawn(|| async {
        AsyncHandler::spawn_blocking(init_scheme);
        AsyncHandler::spawn_blocking(init_embed_server);
    });
}

pub fn resolve_setup_async() {
    AsyncHandler::spawn(|| async {
        logging!(info, Type::ClashVergeRev, "Version: {}", env!("CARGO_PKG_VERSION"));

        init_startup_script().await;
        init_verge_config().await;
        Config::verify_config_initialization().await;
        init_window().await;

        let core_init = AsyncHandler::spawn(|| async {
            init_service_manager().await;
            init_core_manager().await;
            init_system_proxy().await;
            init_system_proxy_guard().await;
        });

        let tray_init = async {
            init_tray().await;
            refresh_tray_menu().await;
        };

        let _ = futures::join!(
            core_init,
            tray_init,
            init_timer(),
            init_hotkey(),
            init_auto_lightweight_boot(),
            init_auto_backup(),
        );
    });
}

pub async fn resolve_reset_async() -> Result<(), anyhow::Error> {
    sysopt::Sysopt::global().reset_sysproxy().await?;
    CoreManager::global().stop_core().await?;

    #[cfg(target_os = "macos")]
    {
        use dns::restore_public_dns;
        restore_public_dns().await;
    }

    Ok(())
}

pub(super) fn init_scheme() {
    logging_error!(Type::Setup, init::init_scheme());
}

pub async fn resolve_scheme(param: &str) -> Result<()> {
    logging_error!(Type::Setup, scheme::resolve_scheme(param).await);
    Ok(())
}

pub(super) fn init_embed_server() {
    server::embed_server();
}

pub(super) async fn init_resources() {
    logging_error!(Type::Setup, init::init_resources().await);
}

pub(super) async fn init_startup_script() {
    logging_error!(Type::Setup, init::startup_script().await);
}

pub(super) async fn init_timer() {
    logging_error!(Type::Setup, Timer::global().init().await);
}

pub fn trigger_startup_subscription_update() {
    if STARTUP_SUBSCRIPTION_UPDATE_TRIGGERED
        .compare_exchange(false, true, Ordering::SeqCst, Ordering::SeqCst)
        .is_err()
    {
        return;
    }

    AsyncHandler::spawn(|| async move {
        tokio::time::sleep(Duration::from_millis(1500)).await;

        let success = update_all_subscriptions_on_startup().await;
        if !success {
            logging!(warn, Type::Setup, "启动自动更新订阅首次尝试未成功，15秒后重试一次");
            tokio::time::sleep(Duration::from_secs(15)).await;
            let _ = update_all_subscriptions_on_startup().await;
        }
    });
}

pub async fn update_all_subscriptions_on_startup() -> bool {
    let remote_uids = {
        let profiles = Config::profiles().await;
        let profiles_ref = profiles.latest_arc();

        profiles_ref
            .get_items()
            .map(|items| {
                items
                    .iter()
                    .filter_map(|item| {
                        if item.itype.as_deref() == Some("remote") {
                            item.uid.clone()
                        } else {
                            None
                        }
                    })
                    .collect::<Vec<_>>()
            })
            .unwrap_or_default()
    };

    if remote_uids.is_empty() {
        logging!(info, Type::Setup, "启动自动更新订阅：未找到远程订阅，跳过");
        return false;
    }

    logging!(
        info,
        Type::Setup,
        "启动自动更新订阅：准备更新 {} 个远程订阅",
        remote_uids.len()
    );

    let mut failed = 0usize;

    for uid in &remote_uids {
        if let Err(error) = feat::update_profile(uid, None, false, true, false).await {
            failed += 1;
            logging!(warn, Type::Setup, "启动自动更新订阅失败，uid={}: {}", uid, error);
        }
    }

    Config::profiles().await.apply();

    match CoreManager::global().update_config().await {
        Ok(_) => {
            Handle::refresh_clash();
        }
        Err(error) => {
            logging!(warn, Type::Setup, "启动自动更新订阅后刷新内核配置失败: {}", error);
        }
    }

    let success = remote_uids.len().saturating_sub(failed);
    logging!(
        info,
        Type::Setup,
        "启动自动更新订阅完成：成功 {}，失败 {}",
        success,
        failed
    );

    success > 0
}

pub(super) async fn init_hotkey() {
    // if hotkey is not use by global, skip init it
    let skip_register_hotkeys = !Config::verge().await.latest_arc().enable_global_hotkey.unwrap_or(true);
    logging_error!(Type::Setup, Hotkey::global().init(skip_register_hotkeys).await);
}

pub(super) async fn init_auto_lightweight_boot() {
    logging_error!(Type::Setup, auto_lightweight_boot().await);
}

pub(super) async fn init_auto_backup() {
    logging_error!(Type::Setup, AutoBackupManager::global().init().await);
}

pub fn init_signal() {
    logging!(info, Type::Setup, "Initializing signal handlers...");
    clash_verge_signal::register(feat::quit);
}

pub async fn init_work_config() {
    logging_error!(Type::Setup, init::init_config().await);
}

pub(super) async fn init_tray() {
    logging_error!(Type::Setup, Tray::global().init().await);
}

pub(super) async fn init_verge_config() {
    logging_error!(Type::Setup, Config::init_config().await);
}

pub(super) async fn init_service_manager() {
    clash_verge_service_ipc::set_config(Some(ServiceManager::config())).await;
    if !is_service_ipc_path_exists() {
        return;
    }
    if SERVICE_MANAGER.lock().await.init().await.is_ok() {
        logging_error!(Type::Setup, SERVICE_MANAGER.lock().await.refresh().await);
    }
}

pub(super) async fn init_core_manager() {
    logging_error!(Type::Setup, CoreManager::global().init().await);
}

pub(super) async fn init_system_proxy() {
    logging_error!(Type::Setup, sysopt::Sysopt::global().update_sysproxy().await);
}

pub(super) async fn init_system_proxy_guard() {
    sysopt::Sysopt::global().refresh_guard().await;
}

pub(super) async fn refresh_tray_menu() {
    logging_error!(Type::Setup, Tray::global().update_part().await);
}

pub(super) async fn init_window() {
    let is_silent_start = Config::verge().await.data_arc().enable_silent_start.unwrap_or(false);
    #[cfg(target_os = "macos")]
    if is_silent_start {
        use crate::core::handle::Handle;
        Handle::global().set_activation_policy_accessory();
    }
    WindowManager::create_window(!is_silent_start).await;
}

pub fn resolve_done() {
    RESOLVE_DONE.store(true, Ordering::Release);
}

pub fn is_resolve_done() -> bool {
    RESOLVE_DONE.load(Ordering::Acquire)
}

pub fn reset_resolve_done() {
    RESOLVE_DONE.store(false, Ordering::Release);
}
