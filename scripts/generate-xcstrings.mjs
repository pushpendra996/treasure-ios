#!/usr/bin/env node
/**
 * Convert Android values[-xx]/strings.xml into Treasure/Localizable.xcstrings
 */
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ANDROID_RES = path.join(
  __dirname,
  "../../treasure-android/app/src/main/res"
);
const OUT = path.join(__dirname, "../Treasure/Localizable.xcstrings");
const LOCALES = [
  "en",
  "hi",
  "bn",
  "te",
  "mr",
  "ta",
  "gu",
  "kn",
  "ml",
  "pa",
  "fr",
  "es",
  "ar",
];

const SKIP = new Set([
  "hello_blank_fragment",
  "notification_channel_id",
  "expense_reminder_channel_id",
]);

const IOS_EXTRAS = {
  hint_done: "Done",
  hint_continue: "Continue",
  hint_select_country: "Select Country",
  hint_enter_mobile: "Enter your mobile number",
  hint_send_code_subtitle: "We'll send you a verification code",
  hint_transaction_details: "Transaction Details",
  hint_edit_transaction: "Edit Transaction",
  hint_duplicate_transaction: "Duplicate Transaction",
  hint_delete_transaction: "Delete Transaction",
  hint_unable_to_load: "Unable to Load",
  hint_no_committees_title: "No Committees",
  hint_loading: "Loading…",
  hint_update_available_title: "Update available",
  hint_update_available_body:
    "A new version of Treasure is ready on the App Store.",
  hint_update_now: "Update",
  hint_later: "Later",
  hint_open_ios_settings: "Open iOS Settings",
  hint_create: "Create",
  hint_sign_out: "Sign Out",
  hint_notifications_enabled: "Notifications are enabled",
  hint_notifications_disabled: "Notifications are off",
  hint_reminders_on: "Reminders on",
  hint_reminders_off: "Reminders off",
  hint_manage_permissions_ios_intro:
    "Optional controls. Turn reminders on if you want twice-daily prompts to log expenses.",
  hint_share_app_body:
    "Track every expense, see where your money goes, and stay in control — free on iPhone and Android.",
  hint_share_app_message:
    "Still guessing where your money went each month?\n\nTreasure helps you track every expense, see clear reports, and stay on top of your finances — free on iPhone and Android.\n\nDownload here:\n%1$@",
  hint_report: "Report",
  hint_settings: "Settings",
  hint_ok: "OK",
  hint_error: "Error",
  hint_timeframe: "Timeframe",
  hint_no_transactions_month: "No transactions this month",
  hint_no_transactions_yet: "No transactions yet",
  hint_where_spent: "Where (optional)",
};

function parseStringsXml(filePath) {
  if (!fs.existsSync(filePath)) return {};
  const xml = fs.readFileSync(filePath, "utf8");
  const out = {};
  const re = /<string\s+name="([^"]+)"[^>]*>([\s\S]*?)<\/string>/g;
  let m;
  while ((m = re.exec(xml))) {
    const key = m[1];
    if (SKIP.has(key)) continue;
    out[key] = decodeAndroid(m[2]);
  }
  return out;
}

function decodeAndroid(raw) {
  let s = raw
    .replace(/<!\[CDATA\[([\s\S]*?)\]\]>/g, "$1")
    .replace(/&amp;/g, "&")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&quot;/g, '"')
    .replace(/&apos;/g, "'")
    .replace(/&app_name;/g, "Treasure")
    .replace(/\\'/g, "'")
    .replace(/\\"/g, '"')
    .replace(/\\n/g, "\n")
    .replace(/\\u([0-9a-fA-F]{4})/g, (_, h) =>
      String.fromCharCode(parseInt(h, 16))
    );
  s = s.replace(/<\/?[^>]+>/g, "");
  s = s.replace(/%(\d+)\$s/g, "%$1$@");
  s = s.replace(/%s/g, "%@");
  return s;
}

function localeFolder(code) {
  return code === "en" ? "values" : `values-${code}`;
}

const byLocale = {};
for (const code of LOCALES) {
  byLocale[code] = parseStringsXml(
    path.join(ANDROID_RES, localeFolder(code), "strings.xml")
  );
}

for (const [key, value] of Object.entries(IOS_EXTRAS)) {
  if (!byLocale.en[key] || key.startsWith("hint_share_app_")) {
    byLocale.en[key] = value;
  }
}

const keys = new Set([
  ...Object.keys(byLocale.en),
  ...Object.keys(IOS_EXTRAS),
]);

const strings = {};
for (const key of [...keys].sort()) {
  const localizations = {};
  for (const code of LOCALES) {
    let value = byLocale[code][key];
    if (value == null && code === "en") value = IOS_EXTRAS[key];
    if (value == null) continue;
    if (key === "hint_share_app_body" || key === "hint_share_app_message") {
      if (code === "en") value = IOS_EXTRAS[key];
      else {
        value = value
          .replace(/free on Android/gi, "free on iPhone and Android")
          .replace(/%1\$s/g, "%1$@");
      }
    }
    localizations[code] = {
      stringUnit: { state: "translated", value },
    };
  }
  strings[key] = { localizations };
}

const catalog = {
  sourceLanguage: "en",
  strings,
  version: "1.1",
};

fs.mkdirSync(path.dirname(OUT), { recursive: true });
fs.writeFileSync(OUT, JSON.stringify(catalog, null, 2) + "\n");
console.log(`Wrote ${Object.keys(strings).length} keys to ${OUT}`);
