import { useState, useEffect } from 'react'
import { Box } from '@mantine/core'
import { notifications } from '@mantine/notifications'
import GarageView from './components/GarageView'
import ImpoundView from './components/ImpoundView'
import SpawnerView from './components/SpawnerView'
import AdminPanel from './components/AdminPanel'
import { useNuiEvent } from './hooks/useNuiEvent'
import { fetchNui } from './utils/fetchNui'

interface Garage {
  name: string
  label: string
  type: string
  max_vehicles: number
  vehicle_types: string[]
}

interface Impound {
  name: string
  label: string
  type: string
  retrieval_fee: number
  release_time: number
}

interface Spawner {
  name: string
  label: string
  type: string
  job?: string
  gang?: string
  vehicles: Array<{ model: string; label: string }>
}

type ViewMode = 'garage' | 'impound' | 'spawner' | 'admin' | null

function App() {
  const [visible, setVisible] = useState(false)
  const [viewMode, setViewMode] = useState<ViewMode>(null)
  const [currentGarage, setCurrentGarage] = useState<Garage | null>(null)
  const [currentImpound, setCurrentImpound] = useState<Impound | null>(null)
  const [currentSpawner, setCurrentSpawner] = useState<Spawner | null>(null)

  // Handle opening garage
  useNuiEvent<{ garage: Garage }>('openGarage', (data) => {
    setCurrentGarage(data.garage)
    setViewMode('garage')
    setVisible(true)
  })

  // Handle opening impound
  useNuiEvent<{ impound: Impound }>('openImpound', (data) => {
    setCurrentImpound(data.impound)
    setViewMode('impound')
    setVisible(true)
  })

  // Handle opening spawner
  useNuiEvent<{ spawner: Spawner }>('openSpawner', (data) => {
    setCurrentSpawner(data.spawner)
    setViewMode('spawner')
    setVisible(true)
  })

  // Handle opening admin panel
  useNuiEvent('openAdminPanel', () => {
    setViewMode('admin')
    setVisible(true)
  })

  // Handle closing UI
  const handleClose = () => {
    setVisible(false)
    setViewMode(null)
    setCurrentGarage(null)
    setCurrentImpound(null)
    setCurrentSpawner(null)
    
    // Send close event to client
    fetchNui('closeUI')
  }

  // Handle escape key
  useEffect(() => {
    const handleKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape' && visible) {
        handleClose()
      }
    }

    window.addEventListener('keydown', handleKeyDown)
    return () => window.removeEventListener('keydown', handleKeyDown)
  }, [visible])

  // Development mode - show UI for testing
  useEffect(() => {
    if (import.meta.env.DEV) {
      // Auto-open garage for development
      setCurrentGarage({
        name: 'legion_garage',
        label: 'Legion Square Garage',
        type: 'public',
        max_vehicles: 10,
        vehicle_types: ['car']
      })
      setViewMode('garage')
      setVisible(true)
    }
  }, [])

  if (!visible) {
    return null
  }

  return (
    <Box
      style={{
        position: 'fixed',
        top: 0,
        left: 0,
        width: '100vw',
        height: '100vh',
        backgroundColor: 'rgba(0, 0, 0, 0.5)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        zIndex: 1000,
      }}
      onClick={(e) => {
        if (e.target === e.currentTarget) {
          handleClose()
        }
      }}
    >
      {viewMode === 'garage' && currentGarage && (
        <GarageView garage={currentGarage} onClose={handleClose} />
      )}
      
      {viewMode === 'impound' && currentImpound && (
        <ImpoundView impound={currentImpound} onClose={handleClose} />
      )}
      
      {viewMode === 'spawner' && currentSpawner && (
        <SpawnerView spawner={currentSpawner} onClose={handleClose} />
      )}
      
      {viewMode === 'admin' && (
        <AdminPanel onClose={handleClose} />
      )}
    </Box>
  )
}

export default App