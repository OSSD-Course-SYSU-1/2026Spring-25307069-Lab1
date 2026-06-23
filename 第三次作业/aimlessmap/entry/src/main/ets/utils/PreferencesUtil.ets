import { preferences } from '@kit.ArkData';

const STORE_NAME = 'aimless_map_store';

export class StoreKeys {
  static readonly WALK_COUNT = 'walk_count';
  static readonly TOTAL_DURATION = 'total_duration';
  static readonly WALK_RECORDS = 'walk_records';
  static readonly IS_DARK_MODE = 'is_dark_mode';
  static readonly SOUND_ENABLED = 'sound_enabled';
  static readonly SOUND_VOLUME = 'sound_volume';
  static readonly SOUND_TYPE = 'sound_type';
  static readonly CUSTOM_AUDIO_URI = 'custom_audio_uri';
  static readonly CUSTOM_AUDIO_NAME = 'custom_audio_name';
}

class PreferencesUtil {
  private pref: preferences.Preferences | null = null;
  async init(ctx: Context) { this.pref = await preferences.getPreferences(ctx, STORE_NAME); }
  private async ensure() { if (!this.pref) await this.init(getContext()); return this.pref!; }
  async put(key: string, val: preferences.ValueType) { const p = await this.ensure(); await p.put(key, val); await p.flush(); }
  async get(key: string, def: preferences.ValueType = ''): Promise<preferences.ValueType> { const p = await this.ensure(); return await p.get(key, def); }
  async clear() { const p = await this.ensure(); await p.clear(); await p.flush(); }
}
export const preferencesUtil = new PreferencesUtil();
