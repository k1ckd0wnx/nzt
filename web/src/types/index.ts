export interface User {
  id: number
  username: string
  balance: number
  sessionToken: string
  totalDeposited?: number
  totalWithdrawn?: number
  totalWagered?: number
  totalWon?: number
}

export interface CasinoConfig {
  casinoName: string
  minBets: {
    slots: number
    plinko: number
    mines: number
    aviator: number
  }
  maxBets: {
    slots: number
    plinko: number
    mines: number
    aviator: number
  }
  slotMachines: {
    [key: string]: SlotMachineConfig
  }
}

export interface SlotMachineConfig {
  name: string
  theme: string
  symbols: string[]
  payouts: {
    three_of_kind: { [symbol: string]: number }
    jackpot: number
  }
  wilds: string[]
  sounds: {
    spin: string
    win: string
    jackpot: string
  }
}

export interface SlotOutcome {
  reels: string[]
  isWin: boolean
  multiplier: number
  winType: string
  payout: number
}

export interface PlinkoOutcome {
  finalPosition: number
  multiplier: number
  payout: number
  path: number[]
}

export interface MinesGame {
  mineCount: number
  revealedSafe: number
  currentMultiplier: number
  currentPayout: number
  isActive: boolean
  grid: (boolean | null)[] // null = hidden, true = mine, false = safe
}

export interface AviatorState {
  isActive: boolean
  currentMultiplier: number
  crashed: boolean
  userBet?: {
    amount: number
    autoCashOut?: number
    cashedOut: boolean
    payout?: number
  }
}

export interface Transaction {
  id: number
  type: 'deposit' | 'withdrawal' | 'game_bet' | 'game_win' | 'game_loss'
  amount: number
  balance_before: number
  balance_after: number
  game_type?: string
  game_data?: any
  created_at: string
  status: 'pending' | 'completed' | 'failed' | 'cancelled'
}

export interface GameEvents {
  REGISTER: string
  LOGIN: string
  LOGOUT: string
  DEPOSIT: string
  WITHDRAW: string
  GET_BALANCE: string
  GET_TRANSACTIONS: string
  SLOTS_SPIN: string
  PLINKO_DROP: string
  MINES_REVEAL: string
  MINES_CASHOUT: string
  AVIATOR_BET: string
  AVIATOR_CASHOUT: string
  OPEN_APP: string
  CLOSE_APP: string
  UPDATE_UI: string
}

export interface UIUpdate {
  action: string
  [key: string]: any
}

export interface GamePage {
  id: string
  name: string
  icon: string
  component: React.ComponentType
}

export type GameType = 'slots' | 'plinko' | 'mines' | 'aviator'

export interface AppState {
  isInitialized: boolean
  user: User | null
  config: CasinoConfig | null
  currentPage: string
  isLoading: boolean
  error: string | null
}