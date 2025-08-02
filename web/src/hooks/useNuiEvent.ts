import { useEffect, useRef } from 'react'

type NuiHandlerSignature<T> = (data: T) => void

/**
 * A hook that manages a NUI event listener.
 */
export const useNuiEvent = <T = any>(
  action: string,
  handler: (data: T) => void,
) => {
  const savedHandler = useRef<NuiHandlerSignature<T>>()

  // Remember the latest handler.
  useEffect(() => {
    savedHandler.current = handler
  }, [handler])

  useEffect(() => {
    const eventListener = (event: MessageEvent) => {
      const { action: eventAction, data } = event.data

      if (savedHandler.current) {
        if (eventAction === action) {
          savedHandler.current(data)
        }
      }
    }

    window.addEventListener('message', eventListener)

    // Remove the event listener on cleanup
    return () => window.removeEventListener('message', eventListener)
  }, [action])
}