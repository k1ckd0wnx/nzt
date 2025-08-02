/**
 * Simple wrapper around fetch API tailored for NUI
 */
export async function fetchNui<T = any>(
  eventName: string,
  data?: any,
  mockResponse?: T,
): Promise<T> {
  const options = {
    method: 'post',
    headers: {
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: JSON.stringify(data),
  }

  if (import.meta.env.DEV && mockResponse) {
    return mockResponse
  }

  const resourceName = (window as any).GetParentResourceName
    ? (window as any).GetParentResourceName()
    : 'advanced-garage'

  const resp = await fetch(`https://${resourceName}/${eventName}`, options)

  const respFormatted = await resp.json()

  return respFormatted
}