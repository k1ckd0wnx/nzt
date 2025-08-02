import React from 'react'
import ReactDOM from 'react-dom/client'
import { MantineProvider } from '@mantine/core'
import { Notifications } from '@mantine/notifications'
// import { ModalsProvider } from '@mantine/modals'
import App from './App'
import { theme } from './theme'
import { LocaleProvider } from './hooks/useLocale'

// Import Mantine CSS
import '@mantine/core/styles.css'
import '@mantine/notifications/styles.css'
// import '@mantine/modals/styles.css'

// Import custom CSS
import './index.css'

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <LocaleProvider>
      <MantineProvider theme={theme} defaultColorScheme="dark">
        <Notifications position="top-right" />
        <App />
      </MantineProvider>
    </LocaleProvider>
  </React.StrictMode>,
)