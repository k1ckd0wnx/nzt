import { useEffect } from 'react'
import { Container, LoadingOverlay, Center, Text, Loader } from '@mantine/core'
import { useAppStore } from '@/store/useAppStore'
import { AuthPage } from '@/pages/AuthPage'
import { LobbyPage } from '@/pages/LobbyPage'
import { SlotsPage } from '@/pages/SlotsPage'
import { PlinkoPage } from '@/pages/PlinkoPage'
import { MinesPage } from '@/pages/MinesPage'
import { AviatorPage } from '@/pages/AviatorPage'
import { BankingPage } from '@/pages/BankingPage'
import { TransactionsPage } from '@/pages/TransactionsPage'
import { Navigation } from '@/components/Navigation'
import { motion, AnimatePresence } from 'framer-motion'

function App() {
  const { 
    isInitialized, 
    currentPage, 
    isLoading, 
    user, 
    config,
    sendNUIMessage
  } = useAppStore()

  // Initialize app when component mounts (for fd_laptop)
  useEffect(() => {
    const initializeApp = async () => {
      try {
        // Check if we're in proper FiveM NUI context
        // @ts-ignore
        const hasNativeAPI = typeof window.invokeNative !== 'undefined' || typeof window.GetParentResourceName !== 'undefined'
        
        if (hasNativeAPI) {
          console.log('Initializing casino app in NUI context...')
          await sendNUIMessage('appLoaded')
        } else {
          console.log('Not in NUI context - casino app should only run inside fd_laptop')
          // Don't initialize outside of FiveM/fd_laptop
        }
      } catch (error) {
        console.log('App initialization error:', error)
        // Emergency fallback - force initialization after 3 seconds if nothing happens
        setTimeout(() => {
          if (!useAppStore.getState().isInitialized) {
            console.log('Emergency initialization - forcing app to load...')
            useAppStore.getState().initialize({
              config: {
                casinoName: "Premium Casino",
                minBets: { slots: 20, plinko: 10, mines: 10, aviator: 10 },
                maxBets: { slots: 10000, plinko: 5000, mines: 5000, aviator: 50000 },
                slotMachines: []
              },
              user: null,
              events: {}
            })
          }
        }, 3000)
      }
    }
    
    // Small delay to ensure context is ready
    setTimeout(initializeApp, 1000)
  }, [])

  // Show loading screen until initialized
  if (!isInitialized) {
    return (
      <div className="casino-app">
        <Center h="100vh">
          <div style={{ textAlign: 'center' }}>
            <Loader size="xl" color="blue" />
            <Text mt="md" size="lg" c="white">
              Loading Casino...
            </Text>
            <Text mt="sm" size="sm" c="gray">
              Debug: isInitialized = {isInitialized.toString()}
            </Text>
            <Text mt="sm" size="sm" c="gray">
              Config: {config ? 'Present' : 'Missing'}
            </Text>
            <Text mt="sm" size="sm" c="gray">
              User: {user ? 'Present' : 'Missing'}
            </Text>
            <Text mt="sm" size="sm" c="yellow">
              Check F8 console for debug messages
            </Text>
          </div>
        </Center>
      </div>
    )
  }

  // Show auth page if not logged in
  if (!user) {
    return (
      <div className="casino-app">
        <AuthPage />
      </div>
    )
  }

  // Page components mapping
  const pageComponents = {
    lobby: LobbyPage,
    slots: SlotsPage,
    plinko: PlinkoPage,
    mines: MinesPage,
    aviator: AviatorPage,
    banking: BankingPage,
    transactions: TransactionsPage,
  }

  const CurrentPageComponent = pageComponents[currentPage as keyof typeof pageComponents] || LobbyPage

  return (
    <div className="casino-app">
      <LoadingOverlay 
        visible={isLoading} 
        zIndex={1000}
        overlayProps={{ radius: "sm", blur: 2 }}
        loaderProps={{ color: 'blue', type: 'bars' }}
      />
      
      <Container fluid h="100vh" p={0} style={{ display: 'flex', flexDirection: 'column' }}>
        {/* Navigation */}
        <Navigation />
        
        {/* Main Content */}
        <div style={{ flex: 1, overflow: 'hidden', position: 'relative' }}>
          <AnimatePresence mode="wait">
            <motion.div
              key={currentPage}
              initial={{ opacity: 0, x: 20 }}
              animate={{ opacity: 1, x: 0 }}
              exit={{ opacity: 0, x: -20 }}
              transition={{ duration: 0.3 }}
              style={{ height: '100%', overflow: 'auto' }}
            >
              <CurrentPageComponent />
            </motion.div>
          </AnimatePresence>
        </div>
      </Container>
    </div>
  )
}

export default App