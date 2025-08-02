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
    console.log('Initializing app...', { hasConfig: !!data.config, hasUser: !!data.user })
    
    set({
      config: data.config,
      user: data.user,
      isInitialized: true,
      currentPage: data.user ? 'lobby' : 'auth',
    })
    
    console.log('App initialized successfully')
  },
  
  setTransactions: (transactions) => set({ transactions }),
  
  handleUIUpdate: (update) => {
    const { user } = get()
    
    switch (update.action) {
      case 'initialize_app':
      case 'initializeApp':
        console.log('Initializing app with server config:', update.config)
        console.log('Full update object:', update)
        set({ 
          config: update.config,
          isInitialized: true,
          currentPage: 'auth' // Default to auth page until user data is received
        })
        console.log('App initialized via handleUIUpdate')
        break
        
      case 'show_auth':
        console.log('Server requesting to show auth page')
        set({ 
          currentPage: 'auth',
          isInitialized: true
        })
        break
        
      case 'login_success':
        console.log('Login successful, updating store...', update.user)
        set({ 
          user: update.user,
          currentPage: 'lobby',
          error: null,
          isLoading: false,  // Clear loading state
          isInitialized: true  // Ensure app is marked as initialized on login
        })
        showNotification({
          title: 'Welcome!',
          message: `Logged in as ${update.user.username}`,
          color: 'green',
        })
        break
        
      case 'login_failed':
        console.log('Login failed:', update.message)
        set({ 
          error: update.message,
          isLoading: false  // Clear loading state
        })
        showNotification({
          title: 'Login Failed',
          message: update.message || 'Invalid username or password',
          color: 'red',
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
    // Reduced debugging for better performance
    console.log('NUI message:', event.data?.action || event.data?.type || 'unknown')
    
    // Handle different data formats
    let messageData = event.data
    
    // If data is a string, try to parse it
    if (typeof event.data === 'string') {
      try {
        messageData = JSON.parse(event.data)
        console.log('Parsed string data:', messageData)
      } catch (e) {
        console.log('Failed to parse string data:', e)
        return
      }
    }
    
    if (!messageData || typeof messageData !== 'object') {
      console.log('Invalid NUI message format:', messageData)
      return
    }
    
    const { type, data } = messageData
    
    if (!type) {
      console.log('Missing type in NUI message:', messageData)
      console.log('Available properties:', Object.keys(messageData))
      return
    }
    
    switch (type) {
      case 'openApp':
      case 'initializeApp':
        console.log('Initializing app with data:', data)
        useAppStore.getState().initialize(data)
        break
        
      case 'updateUI':
        console.log('✅ UPDATEUI CASE TRIGGERED!')
        console.log('Updating UI with data:', JSON.stringify(data, null, 2))
        console.log('Data action:', data?.action)
        
        // Handle special initializeApp action within updateUI
        if (data.action === 'initializeApp') {
          console.log('✅ PROCESSING INITIALIZEAPP FROM UPDATEUI:', data)
          useAppStore.getState().initialize({
            config: data.config,
            user: data.user,
            events: data.events
          })
        } else if (data.action === 'login_success') {
          console.log('✅ PROCESSING LOGIN_SUCCESS FROM UPDATEUI:', data)
          useAppStore.getState().handleUIUpdate(data)
        } else {
          console.log('✅ PROCESSING OTHER ACTION:', data.action)
          useAppStore.getState().handleUIUpdate(data)
        }
        break
        
      case 'casino_updateUI':
        console.log('✅ FD_LAPTOP FORMAT DETECTED!')
        console.log('Processing casino update:', JSON.stringify(data, null, 2))
        
        if (data.action === 'initializeApp') {
          console.log('✅ PROCESSING INITIALIZEAPP FROM FD_LAPTOP FORMAT:', data)
          useAppStore.getState().initialize({
            config: data.config,
            user: data.user,
            events: data.events
          })
        } else if (data.action === 'login_success') {
          console.log('✅ PROCESSING LOGIN_SUCCESS FROM FD_LAPTOP FORMAT:', data)
          useAppStore.getState().handleUIUpdate(data)
        } else {
          console.log('✅ PROCESSING OTHER ACTION FROM FD_LAPTOP FORMAT:', data.action)
          useAppStore.getState().handleUIUpdate(data)
        }
        break
        
      case 'closeApp':
        // Handle app close if needed
        break
        
      default:
        console.log('Unknown NUI message type:', type, 'Full message:', event.data)
        
        // Check if this is a direct message with casino data
        if (messageData.source === 'casino' && messageData.action && messageData.payload) {
          console.log('✅ WINDOW MESSAGE FORMAT DETECTED!')
          console.log('Processing casino payload:', JSON.stringify(messageData.payload, null, 2))
          
          if (messageData.action === 'initializeApp') {
            console.log('✅ PROCESSING INITIALIZEAPP FROM WINDOW FORMAT:', messageData.payload)
            useAppStore.getState().initialize({
              config: messageData.payload.config,
              user: messageData.payload.user,
              events: messageData.payload.events
            })
          } else if (messageData.action === 'login_success') {
            console.log('✅ PROCESSING LOGIN_SUCCESS FROM WINDOW FORMAT:', messageData.payload)
            useAppStore.getState().handleUIUpdate(messageData.payload)
          } else {
            console.log('✅ PROCESSING OTHER ACTION FROM WINDOW FORMAT:', messageData.action)
            useAppStore.getState().handleUIUpdate(messageData.payload)
          }
        }
        
        // Also check if this is a direct action message (like fd_laptop sends)
        if (messageData.action && !messageData.type && messageData.action.startsWith('initializeApp')) {
          console.log('✅ DIRECT ACTION MESSAGE DETECTED!')
          console.log('Processing direct action:', JSON.stringify(messageData, null, 2))
          useAppStore.getState().handleUIUpdate(messageData)
        }
    }
  })
  
  // ESC key handling is managed by fd_laptop
}