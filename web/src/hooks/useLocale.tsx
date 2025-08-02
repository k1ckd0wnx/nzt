import React, { useState, useEffect, createContext, useContext, ReactNode } from 'react'

// Locale types
export interface LocaleData {
  ui: Record<string, string>
  auth: Record<string, string>
  nav: Record<string, string>
  games: Record<string, string>
  plinko: Record<string, string>
  banking: Record<string, string>
  notifications: Record<string, string>
  [key: string]: Record<string, string>
}

// Available locales
export const AVAILABLE_LOCALES = {
  en: 'English',
  bg: 'Български'
} as const

export type LocaleCode = keyof typeof AVAILABLE_LOCALES

// Default English locale data
const DEFAULT_LOCALE: LocaleData = {
  ui: {
    casino_name: 'Premium Casino',
    loading: 'Loading...',
    error: 'Error',
    success: 'Success',
    warning: 'Warning',
    info: 'Information',
    confirm: 'Confirm',
    cancel: 'Cancel',
    close: 'Close',
    save: 'Save',
    delete: 'Delete',
    edit: 'Edit',
    view: 'View',
    back: 'Back',
    next: 'Next',
    previous: 'Previous',
    submit: 'Submit',
    reset: 'Reset',
    clear: 'Clear'
  },
  auth: {
    login: 'Login',
    register: 'Register',
    logout: 'Logout',
    username: 'Username',
    password: 'Password',
    login_title: 'Welcome Back!',
    login_subtitle: 'Sign in to access your casino account',
    register_title: 'Join the Casino!',
    register_subtitle: 'Create your account to start playing',
    username_placeholder: 'Enter your username',
    password_placeholder: 'Enter your password',
    login_button: 'Sign In',
    register_button: 'Create Account',
    switch_to_register: "Don't have an account? Register here",
    switch_to_login: 'Already have an account? Login here',
    login_success: 'Successfully logged in!',
    register_success: 'Account created successfully!',
    login_failed: 'Invalid username or password',
    register_failed: 'Registration failed',
    username_required: 'Username is required',
    password_required: 'Password is required',
    username_too_short: 'Username must be at least 3 characters',
    password_too_short: 'Password must be at least 6 characters',
    username_invalid: 'Username can only contain letters, numbers, and underscores',
    logging_in: 'Logging in...',
    registering: 'Creating account...'
  },
  nav: {
    lobby: 'Lobby',
    slots: 'Slots',
    plinko: 'Plinko',
    mines: 'Mines',
    aviator: 'Aviator',
    banking: 'Banking',
    transactions: 'History',
    balance: 'Balance'
  },
  games: {
    bet_amount: 'Bet Amount',
    min_bet: 'Min Bet',
    max_bet: 'Max Bet',
    current_bet: 'Current Bet',
    place_bet: 'Place Bet',
    play: 'Play',
    spin: 'Spin',
    drop_ball: 'Drop Ball',
    reveal: 'Reveal',
    cash_out: 'Cash Out',
    you_won: 'You Won!',
    you_lost: 'You Lost!',
    game_over: 'Game Over',
    win: 'Win',
    loss: 'Loss',
    multiplier: 'Multiplier',
    payout: 'Payout',
    jackpot: 'Jackpot!',
    bonus: 'Bonus',
    free_spins: 'Free Spins',
    wild: 'Wild',
    scatter: 'Scatter',
    autoplay: 'Autoplay',
    max_win: 'Max Win',
    rtp: 'RTP',
    volatility: 'Volatility',
    paylines: 'Paylines',
    insufficient_balance: 'Insufficient balance!',
    bet_too_low: 'Bet amount too low',
    bet_too_high: 'Bet amount too high',
    game_in_progress: 'Game in progress...',
    waiting_for_result: 'Waiting for result...'
  },
  plinko: {
    title: 'Plinko',
    subtitle: 'Drop the ball and watch it bounce through the pegs!',
    dropping: 'Dropping...',
    high_risk: 'High Risk (100x+)',
    medium_risk: 'Medium Risk (10x+)',
    low_risk: 'Low Risk (2x-9x)',
    min: 'Min',
    half: '1/2',
    max: 'Max'
  },
  banking: {
    title: 'Banking',
    subtitle: 'Manage your casino balance',
    deposit: 'Deposit',
    withdraw: 'Withdraw',
    bank_balance: 'Bank Balance',
    casino_balance: 'Casino Balance',
    amount: 'Amount',
    deposit_amount: 'Deposit Amount',
    withdraw_amount: 'Withdraw Amount',
    deposit_button: 'Deposit Funds',
    withdraw_button: 'Withdraw Funds',
    deposit_success: 'Deposit successful!',
    withdraw_success: 'Withdrawal successful!',
    deposit_failed: 'Deposit failed!',
    withdraw_failed: 'Withdrawal failed!',
    insufficient_bank_funds: 'Insufficient bank funds!',
    insufficient_casino_balance: 'Insufficient casino balance!',
    invalid_amount: 'Invalid amount!',
    amount_too_low: 'Amount too low!',
    amount_too_high: 'Amount too high!',
    processing: 'Processing...',
    depositing: 'Depositing...',
    withdrawing: 'Withdrawing...'
  },
  notifications: {
    welcome: 'Welcome to the Casino!',
    login_required: 'Please log in to play',
    session_expired: 'Your session has expired',
    connection_error: 'Connection error',
    server_error: 'Server error',
    rate_limited: 'Please wait before trying again',
    transaction_failed: 'Transaction failed',
    game_error: 'Game error occurred',
    invalid_session: 'Invalid session. Please log in again.',
    too_many_attempts: 'Too many login attempts',
    account_created: 'Account created successfully!',
    logged_out: 'Successfully logged out',
    balance_updated: 'Balance updated',
    winner: 'Winner!',
    better_luck: 'Better luck next time!'
  }
}

// Locale context
interface LocaleContextType {
  locale: LocaleCode
  localeData: LocaleData
  setLocale: (locale: LocaleCode) => void
  updateServerLocale: (serverLocale?: string) => void
  isInitialized: boolean
  t: (key: string, fallback?: string) => string
}

const LocaleContext = createContext<LocaleContextType | null>(null)

// Custom hook to use locale
export function useLocale() {
  const context = useContext(LocaleContext)
  if (!context) {
    // Return fallback context instead of throwing error
    console.warn('useLocale used outside LocaleProvider, using fallback')
    return {
      locale: 'en' as LocaleCode,
      localeData: DEFAULT_LOCALE,
      setLocale: () => {},
      updateServerLocale: () => {},
      isInitialized: true,
      t: (key: string, fallback?: string) => fallback || key
    }
  }
  return context
}

// Locale provider props
interface LocaleProviderProps {
  children: ReactNode
  initialLocale?: LocaleCode
  serverLocale?: string
}

// Locale provider component
export function LocaleProvider({ children, initialLocale = 'en', serverLocale }: LocaleProviderProps) {
  const [locale, setLocaleState] = useState<LocaleCode>(initialLocale)
  const [localeData, setLocaleData] = useState<LocaleData>(DEFAULT_LOCALE)
  const [configReceived, setConfigReceived] = useState(false)
  const [isInitialized, setIsInitialized] = useState(false)

  // Function to load locale data
  const loadLocaleData = async (localeCode: LocaleCode) => {
    try {
      // Get the base URL for NUI context
      const baseUrl = window.location.origin + window.location.pathname.substring(0, window.location.pathname.lastIndexOf('/') + 1)
      const localeUrl = `${baseUrl}locales/${localeCode}.json`
      
      console.log(`Loading locale from: ${localeUrl}`)
      
      // Try to load locale from the server
      const response = await fetch(localeUrl)
      if (response.ok) {
        const data = await response.json()
        console.log(`Successfully loaded locale ${localeCode}:`, data)
        setLocaleData({ ...DEFAULT_LOCALE, ...data })
      } else {
        console.warn(`Failed to fetch locale ${localeCode}, status: ${response.status}`)
        // Fallback to default locale
        setLocaleData(DEFAULT_LOCALE)
      }
    } catch (error) {
      console.warn(`Failed to load locale ${localeCode}, using default:`, error)
      setLocaleData(DEFAULT_LOCALE)
    } finally {
      setIsInitialized(true)
    }
  }

  // Set locale and load data
  const setLocale = (newLocale: LocaleCode) => {
    console.log(`Setting locale to: ${newLocale}`)
    setLocaleState(newLocale)
    loadLocaleData(newLocale)
    localStorage.setItem('casino-locale', newLocale)
  }



  // Translation function with safety checks
  const t = (key: string, fallback?: string): string => {
    try {
      if (!localeData || !key) {
        return fallback || key
      }

      const keys = key.split('.')
      let value: any = localeData

      for (const k of keys) {
        if (value && typeof value === 'object' && k in value) {
          value = value[k]
        } else {
          // Debug: log when a key is not found
          if (locale !== 'en' && isInitialized) {
            console.log(`Translation key '${key}' not found in locale '${locale}', using fallback`)
          }
          return fallback || key
        }
      }

      return typeof value === 'string' ? value : (fallback || key)
    } catch (error) {
      console.warn(`Translation error for key '${key}':`, error)
      return fallback || key
    }
  }

  // Initialize locale from localStorage
  useEffect(() => {
    const initializeLocale = async () => {
      const savedLocale = localStorage.getItem('casino-locale') as LocaleCode
      let targetLocale: LocaleCode = 'en'
      
      if (serverLocale && serverLocale in AVAILABLE_LOCALES) {
        // Use server locale if no saved preference
        targetLocale = (savedLocale && savedLocale in AVAILABLE_LOCALES) ? savedLocale : serverLocale as LocaleCode
      } else if (savedLocale && savedLocale in AVAILABLE_LOCALES) {
        // Use saved preference
        targetLocale = savedLocale
      }
      
      console.log(`Initializing locale: ${targetLocale}`)
      setLocaleState(targetLocale)
      await loadLocaleData(targetLocale)
    }
    
    initializeLocale()
  }, [serverLocale])

  // Dynamic server locale handler function that can be called from outside
  const updateServerLocale = (newServerLocale?: string) => {
    if (newServerLocale && newServerLocale in AVAILABLE_LOCALES) {
      const savedLocale = localStorage.getItem('casino-locale') as LocaleCode
      const targetLocale = (savedLocale && savedLocale in AVAILABLE_LOCALES) ? savedLocale : newServerLocale as LocaleCode
      
      console.log(`Updating to server locale: ${newServerLocale}, using: ${targetLocale}`)
      setLocaleState(targetLocale)
      loadLocaleData(targetLocale)
    }
  }

  const contextValue: LocaleContextType = {
    locale,
    localeData,
    setLocale,
    updateServerLocale,
    isInitialized,
    t
  }

  return (
    <LocaleContext.Provider value={contextValue}>
      {children}
    </LocaleContext.Provider>
  )
}