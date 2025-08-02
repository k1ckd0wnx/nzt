import { useEffect, memo, lazy, Suspense } from 'react'
import { Container, LoadingOverlay, Center, Text, Loader } from '@mantine/core'
import { useAppStore } from '@/store/useAppStore'
import { Navigation } from '@/components/Navigation'
import { motion, AnimatePresence } from 'framer-motion'

// Lazy load pages for better performance
const AuthPage = lazy(() => import('@/pages/AuthPage').then(module => ({ default: module.AuthPage })))
const LobbyPage = lazy(() => import('@/pages/LobbyPage').then(module => ({ default: module.LobbyPage })))
const SlotsPage = lazy(() => import('@/pages/SlotsPage').then(module => ({ default: module.SlotsPage })))
const PlinkoPage = lazy(() => import('@/pages/PlinkoPage').then(module => ({ default: module.PlinkoPage })))
const MinesPage = lazy(() => import('@/pages/MinesPage').then(module => ({ default: module.MinesPage })))
const AviatorPage = lazy(() => import('@/pages/AviatorPage').then(module => ({ default: module.AviatorPage })))
const BankingPage = lazy(() => import('@/pages/BankingPage').then(module => ({ default: module.BankingPage })))
const TransactionsPage = lazy(() => import('@/pages/TransactionsPage').then(module => ({ default: module.TransactionsPage })))

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
            const response = await sendNUIMessage('appLoaded')
            console.log('AppLoaded response:', response)
            
            // Handle direct initialization from callback response
            if (response && response.action === 'directInit') {
              console.log('✅ DIRECT INIT RECEIVED FROM CALLBACK!')
              console.log('Direct init data:', response)
              
              useAppStore.getState().initialize({
                config: response.config,
                user: response.user,
                events: {}
              })
              
              console.log('App initialized via direct callback response')
            }
          } else {
            console.log('Not in NUI context - casino app should only run inside fd_laptop')
            // Don't initialize outside of FiveM/fd_laptop
          }
              } catch (error) {
          console.log('App initialization error:', error)
        }
        
        // Quick fallback - force initialization if no server response after 1 second
        setTimeout(() => {
          if (!useAppStore.getState().isInitialized) {
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
        }, 1000)
      }
    
    // Small delay to ensure context is ready
    setTimeout(initializeApp, 1000)
    
    // Quick polling for data (reduced frequency for better performance)
    const pollForData = () => {
      const { isInitialized, user } = useAppStore.getState()
      if (!isInitialized || !user) {
        sendNUIMessage('pollForData', { 
          timestamp: Date.now(),
          needsInit: !isInitialized,
          needsUser: !user
        })
      }
    }
    
    // Poll every 1 second for the first 10 seconds only
    const pollInterval = setInterval(pollForData, 1000)
    setTimeout(() => {
      clearInterval(pollInterval)
    }, 10000)
    
  }, [])

  // Show minimal loading screen
  if (!isInitialized) {
    return (
      <div className="casino-app">
        <Center h="100vh">
          <div style={{ textAlign: 'center' }}>
            <Loader size="lg" color="blue" />
            <Text mt="md" size="md" c="white" fw={500}>
              Loading...
            </Text>
          </div>
        </Center>
      </div>
    )
  }

  // Loading fallback component
  const PageLoader = () => (
    <Center h="100vh">
      <div style={{ textAlign: 'center' }}>
        <Loader size="md" color="blue" />
        <Text mt="md" size="sm" c="dimmed">Loading...</Text>
      </div>
    </Center>
  )

  // Show auth page if not logged in
  if (!user) {
    return (
      <div className="casino-app">
        <Suspense fallback={<PageLoader />}>
          <motion.div
            initial={{ opacity: 0, x: -20 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: 20 }}
            transition={{ duration: 0.3, ease: 'easeOut' }}
            className="fade-in-up"
          >
            <AuthPage />
          </motion.div>
        </Suspense>
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
              initial={{ opacity: 0, x: 8 }}
              animate={{ opacity: 1, x: 0 }}
              exit={{ opacity: 0, x: -8 }}
              transition={{ duration: 0.12, ease: [0.25, 0.46, 0.45, 0.94] }}
              style={{ 
                height: '100%', 
                overflow: 'auto',
                transform: 'translate3d(0, 0, 0)',
                willChange: 'transform, opacity'
              }}
              className="fade-in-up"
            >
              <Suspense fallback={<PageLoader />}>
                <CurrentPageComponent />
              </Suspense>
            </motion.div>
          </AnimatePresence>
        </div>
      </Container>
    </div>
  )
}

export default memo(App)