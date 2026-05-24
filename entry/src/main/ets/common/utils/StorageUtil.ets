import { preferences } from '@kit.ArkData'

const STORE_NAME = 'youthlink_prefs'
let dataPreferences: preferences.Preferences | null = null

export async function initStorage(context: Context): Promise<void> {
  if (dataPreferences === null) {
    dataPreferences = await preferences.getPreferences(context, STORE_NAME)
  }
}

export async function putString(key: string, value: string): Promise<void> {
  if (dataPreferences) {
    await dataPreferences.put(key, value)
    await dataPreferences.flush()
  }
}

export async function getString(key: string, defaultValue: string = ''): Promise<string> {
  if (dataPreferences) {
    return await dataPreferences.get(key, defaultValue) as string
  }
  return defaultValue
}

export async function putBoolean(key: string, value: boolean): Promise<void> {
  if (dataPreferences) {
    await dataPreferences.put(key, value)
    await dataPreferences.flush()
  }
}

export async function getBoolean(key: string, defaultValue: boolean = false): Promise<boolean> {
  if (dataPreferences) {
    return await dataPreferences.get(key, defaultValue) as boolean
  }
  return defaultValue
}

export async function putNumber(key: string, value: number): Promise<void> {
  if (dataPreferences) {
    await dataPreferences.put(key, value)
    await dataPreferences.flush()
  }
}

export async function getNumber(key: string, defaultValue: number = 0): Promise<number> {
  if (dataPreferences) {
    return await dataPreferences.get(key, defaultValue) as number
  }
  return defaultValue
}

export async function remove(key: string): Promise<void> {
  if (dataPreferences) {
    await dataPreferences.delete(key)
    await dataPreferences.flush()
  }
}

export async function clearAll(): Promise<void> {
  if (dataPreferences) {
    await dataPreferences.clear()
    await dataPreferences.flush()
  }
}

export async function hasKey(key: string): Promise<boolean> {
  if (dataPreferences) {
    return await dataPreferences.has(key)
  }
  return false
}
