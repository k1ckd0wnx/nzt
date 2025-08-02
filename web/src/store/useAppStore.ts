import { create } from 'zustand'
import { AppState, User, CasinoConfig, Transaction, UIUpdate } from '@/types'
import { showNotification } from '@mantine/notifications'

interface AppStore extends AppState {
  // Actions
  setUser: (user: User | null) => void
  setConfig: (config: CasinoConfig) => void
  setCurrentPage: (page: string) => void
  setLoading: (loading: boolean) => void
  setError: (error: string | null) => void
  updateBalance: (balance: number) => void
  initialize: (data: any) => void
  handleUIUpdate: (update: UIUpdate) => void
  
  // Game-specific state
  transactions: Transaction[]
  setTransactions: (transactions: Transaction[]) => void
  
  // NUI Communication
  sendNUIMessage: (action: string, data?: any) => Promise<any>
}

// Get resource name helper
const GetParentResourceName = (): string => {
  // @ts-ignore - FiveM NUI function
  return window.GetParentResourceName ? window.GetParentResourceName() : 'casino'
}

// NUI Communication helper
const sendNUIMessage = async (action: string, data?: any): Promise<any> => {
  return new Promise((resolve, reject) => {
    try {
      // Check if we're in a proper NUI context
      // @ts-ignore - FiveM NUI functions
      if (typeof window.invokeNative === 'undefined' && typeof window.GetParentResourceName === 'undefined') {
        console.log('Not in NUI context, skipping callback')
        reject(new Error('Not in NUI context'))
        return
      }

      // @ts-ignore - NUI callback function
      fetch(`https://${GetParentResourceName()}/${action}`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(data || {}),
      })
        .then(response => response.json())
        .then(resolve)
        .catch(reject)
    } catch (error) {
      reject(error)
    }
  })
}

export const useAppStore = create<AppStore>((set, get) => ({
  // Initial state
  isInitialized: false,
  user: null,
  config: null,
  currentPage: 'lobby',
  isLoading: false,
  error: null,
  transactions: [],

  // Actions
  setUser: (user) => set({ user }),
  
  setConfig: (config) => set({ config }),
  
  setCurrentPage: (page) => set({ currentPage: page }),
  
  setLoading: (loading) => set({ isLoading: loading }),
  
  setError: (error) => {
    set({ error })
    if (error) {
      showNotification({
        title: 'Error',
        message: error,
        color: 'red',
      })
    }
  },
  
  updateBalance: (balance) => {
    const { user } = get()
    if (user) {
      set({ user: { ...user, balance } })
    }
  },
  
  initialize: (data) => {
    set({
      config: data.config,
      user: data.user,
      isInitialized: true,
      currentPage: data.user ? 'lobby' : 'auth',
    })
  },
  
  setTransactions: (transactions) => set({ transactions }),
  
  handleUIUpdate: (update) => {
    const { user } = get()
    
    switch (update.action) {
      case 'initialize_app':
        console.log('Initializing app with server config:', update.config)
        set({ 
          config: update.config,
          isInitialized: true,
          currentPage: 'auth' // Default to auth page until user data is received
        })
        break
        
      case 'login_success':
        set({ 
          user: update.user,
          currentPage: 'lobby',
          error: null 
        })
        showNotification({
          title: 'Welcome!',
          message: `Logged in as ${update.user.username}`,
          color: 'green',
        })
        break
        
      case 'registration_success':
        showNotification({
          title: 'Success!',
          message: 'Account created successfully. You can now log in.',
          color: 'green',
        })
        break
        
      case 'logout_success':
        set({ 
          user: null,
          currentPage: 'auth',
          transactions: []
        })
        showNotification({
          title: 'Goodbye!',
          message: 'You have been logged out.',
          color: 'blue',
        })
        break
        
      case 'balance_updated':
        if (user) {
          set({ user: { ...user, balance: update.balance } })
        }
        break
        
      case 'transactions_loaded':
        set({ transactions: update.transactions })
        break
        
      case 'session_expired':
        set({ 
          user: null,
          currentPage: 'auth',
          error: 'Your session has expired. Please log in again.'
        })
        break
        
      case 'slots_result':
        // Handle slot result (will be processed by slot component)
        if (update.outcome.isWin) {
          showNotification({
            title: 'Winner!',
            message: `You won $${update.outcome.payout.toFixed(2)}!`,
            color: 'green',
          })
        }
        if (user) {
          set({ user: { ...user, balance: update.balance } })
        }
        break
        
      case 'plinko_result':
        // Handle plinko result
        if (update.outcome.payout > update.outcome.betAmount) {
          showNotification({
            title: 'Winner!',
            message: `You won $${update.outcome.payout.toFixed(2)}!`,
            color: 'green',
          })
        }
        if (user) {
          set({ user: { ...user, balance: update.balance } })
        }
        break
        
      case 'aviator_round_start':
        // Handle aviator round start
        break
        
      case 'aviator_update':
        // Handle aviator state update
        break
        
      case 'aviator_crashed':
        // Handle aviator crash
        showNotification({
          title: 'Crashed!',
          message: `Multiplier crashed at ${update.crashMultiplier.toFixed(2)}x`,
          color: 'red',
        })
        break
        
      default:
        console.log('Unhandled UI update:', update)
    }
  },
  
  sendNUIMessage,
}))

// NUI Event Listener Setup
if (typeof window !== 'undefined') {
  window.addEventListener('message', (event) => {
    const { type, data } = event.data
    
    switch (type) {
      case 'openApp':
      case 'initializeApp':
        console.log('Initializing app with data:', data)
        useAppStore.getState().initialize(data)
        break
        
      case 'updateUI':
        console.log('Updating UI with data:', data)
        useAppStore.getState().handleUIUpdate(data)
        break
        
      case 'closeApp':
        // Handle app close if needed
        break
        
      default:
        console.log('Unknown NUI message type:', type)
    }
  })
  
  // ESC key handling is managed by fd_laptop
}