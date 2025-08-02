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
    config 
  } = useAppStore()

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