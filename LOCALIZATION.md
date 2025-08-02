# 🌍 Casino Localization System

This casino supports multiple languages through a comprehensive localization system. Currently supported languages:

- **English** (`en`) - Default
- **Bulgarian** (`bg`) - Български

## 🔧 **How to Add a New Language**

### **1. Backend Locale (Lua)**

Create a new locale file in the `locales/` directory:

**File**: `locales/[language_code].lua`

```lua
Locale = {}

-- General UI
Locale['ui'] = {
    ['casino_name'] = 'Your Translation',
    ['loading'] = 'Your Translation...',
    ['error'] = 'Your Translation',
    -- ... add all keys from en.lua
}

-- Authentication
Locale['auth'] = {
    ['login'] = 'Your Translation',
    ['register'] = 'Your Translation',
    -- ... add all keys
}

-- ... copy all sections from en.lua and translate

return Locale
```

### **2. Frontend Locale (JSON)**

Create a JSON file for the React frontend:

**File**: `web/public/locales/[language_code].json`

```json
{
  "ui": {
    "casino_name": "Your Translation",
    "loading": "Your Translation...",
    "error": "Your Translation"
  },
  "auth": {
    "login": "Your Translation",
    "register": "Your Translation"
  }
}
```

### **3. Update Configuration**

Add your language to `config.lua`:

```lua
-- Localization Settings
Config.Locale = 'en' -- Change to your language code as default
Config.AvailableLocales = {
    ['en'] = 'English',
    ['bg'] = 'Български',
    ['your_code'] = 'Your Language Name'
}
```

### **4. Update Frontend Hook**

Add your language to `web/src/hooks/useLocale.tsx`:

```typescript
export const AVAILABLE_LOCALES = {
  en: 'English',
  bg: 'Български',
  your_code: 'Your Language Name'
} as const
```

## 📝 **Translation Keys Reference**

### **UI Section**
- `casino_name` - Name of the casino
- `loading` - Loading text
- `error`, `success`, `warning`, `info` - Status messages
- `confirm`, `cancel`, `close` - Common buttons
- `save`, `delete`, `edit`, `view` - Action buttons
- `back`, `next`, `previous` - Navigation
- `submit`, `reset`, `clear` - Form actions

### **Auth Section**
- `login`, `register`, `logout` - Authentication actions
- `username`, `password` - Form fields
- `login_title`, `login_subtitle` - Login page headings
- `register_title`, `register_subtitle` - Register page headings
- `*_placeholder` - Input field placeholders
- `*_button` - Button labels
- `switch_to_*` - Links between login/register
- `*_success`, `*_failed` - Status messages
- `*_required`, `*_too_short`, `*_invalid` - Validation messages
- `logging_in`, `registering` - Loading states

### **Navigation Section**
- `lobby`, `slots`, `plinko`, `mines`, `aviator` - Game names
- `banking`, `transactions` - Account sections
- `balance`, `account`, `profile` - User info

### **Games Section**
- `bet_amount`, `min_bet`, `max_bet`, `current_bet` - Betting
- `place_bet`, `play`, `spin`, `drop_ball` - Game actions
- `reveal`, `cash_out` - Game controls
- `you_won`, `you_lost`, `game_over` - Game outcomes
- `win`, `loss`, `multiplier`, `payout` - Results
- `jackpot`, `bonus`, `free_spins` - Special features
- `wild`, `scatter`, `autoplay` - Slot features
- `max_win`, `rtp`, `volatility`, `paylines` - Game info
- `insufficient_balance` - Error messages
- `bet_too_low`, `bet_too_high` - Validation
- `game_in_progress`, `waiting_for_result` - Status

### **Plinko Section**
- `title`, `subtitle` - Page headers
- `dropping` - Game state
- `high_risk`, `medium_risk`, `low_risk` - Risk levels
- `min`, `half`, `max` - Bet buttons

### **Banking Section**
- `title`, `subtitle` - Page headers
- `deposit`, `withdraw` - Main actions
- `bank_balance`, `casino_balance` - Balance types
- `amount`, `deposit_amount`, `withdraw_amount` - Input labels
- `deposit_button`, `withdraw_button` - Action buttons
- `*_success`, `*_failed` - Transaction results
- `insufficient_*` - Error messages
- `invalid_amount`, `amount_too_*` - Validation
- `processing`, `depositing`, `withdrawing` - Loading states

### **Notifications Section**
- `welcome` - Welcome message
- `login_required` - Access control
- `session_expired` - Session management
- `connection_error`, `server_error` - Technical errors
- `rate_limited` - Anti-spam
- `transaction_failed`, `game_error` - Error messages
- `invalid_session` - Security
- `too_many_attempts` - Rate limiting
- `account_created`, `logged_out` - Success messages
- `balance_updated` - Status updates
- `winner`, `better_luck` - Game outcomes

## 🔧 **How the System Works**

### **Backend (Lua)**
```lua
-- Use _L() function for translations
local message = _L('auth.login_success')

-- Use _LF() for fallback text
local message = _LF('auth.login_success', 'Login successful!')
```

### **Frontend (React)**
```typescript
// Use the t() function from useLocale hook
const { t } = useLocale()
const message = t('auth.login_success')

// With fallback
const message = t('auth.login_success', 'Login successful!')
```

### **Language Switching**
Users can switch languages using the language selector in the navigation menu. The selected language is automatically saved in localStorage and persists across sessions.

## 🌍 **Language Codes**

Use standard ISO 639-1 language codes:
- `en` - English
- `bg` - Bulgarian  
- `es` - Spanish
- `fr` - French
- `de` - German
- `it` - Italian
- `pt` - Portuguese
- `ru` - Russian
- `zh` - Chinese
- `ja` - Japanese
- `ko` - Korean

## 📋 **Testing Your Translation**

1. **Backend**: Change `Config.Locale` in `config.lua` to your language code
2. **Frontend**: Use the language selector in the navigation menu
3. **Verification**: Check all pages and ensure text displays correctly
4. **Fallback**: Test with missing keys to ensure English fallback works

## 🎯 **Best Practices**

1. **Keep text concise** - Casino UI has limited space
2. **Use consistent terminology** - Same terms for same concepts
3. **Consider cultural context** - Gambling terms may vary by region
4. **Test all features** - Ensure translations work in all game states
5. **Handle special characters** - Test with your language's special characters
6. **Maintain formatting** - Preserve placeholders like `%s` for dynamic content

## 🚨 **Important Notes**

- **Always test thoroughly** after adding a new language
- **Keep the same key structure** as English locale
- **Don't leave keys empty** - Use English text as fallback
- **Consider text length** - Some languages need more space
- **Update both backend and frontend** files
- **Rebuild the UI** after making changes to frontend locales