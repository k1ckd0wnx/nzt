import React from 'react'
import ReactDOM from 'react-dom/client'
import { MantineProvider, createTheme } from '@mantine/core'
import { ModalsProvider } from '@mantine/modals'
import { Notifications } from '@mantine/notifications'
import App from './App'
import '@mantine/core/styles.css'
import '@mantine/notifications/styles.css'
import '@mantine/modals/styles.css'
import './index.css'

const theme = createTheme({
  primaryColor: 'blue',
  primaryShade: 6,
  fontFamily: 'Inter, system-ui, Avenir, Helvetica, Arial, sans-serif',
  headings: {
    fontFamily: 'Inter, system-ui, Avenir, Helvetica, Arial, sans-serif',
  },
  colors: {
    blue: [
      '#e7f5ff',
      '#d0ebff',
      '#a5d8ff',
      '#74c0fc',
      '#339af0',
      '#228be6',
      '#1c7ed6',
      '#1971c2',
      '#1864ab',
      '#0b5394'
    ]
  },
  defaultRadius: 'md',
  cursorType: 'pointer',
})

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <MantineProvider theme={theme}>
      <ModalsProvider>
        <Notifications position="top-right" />
        <App />
      </ModalsProvider>
    </MantineProvider>
  </React.StrictMode>,
)