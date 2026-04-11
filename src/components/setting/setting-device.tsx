import { useTranslation } from "react-i18next";
import { useNavigate } from "react-router";

import { deviceNavItems } from "@/pages/_routers";

import { SettingItem, SettingList } from "./mods/setting-comp";

const SettingDevice = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();

  return (
    <SettingList title="设备">
      {deviceNavItems.map((item) => (
        <SettingItem
          key={item.path}
          label={t(item.label)}
          onClick={() => navigate(item.path)}
        />
      ))}
    </SettingList>
  );
};

export default SettingDevice;
