import { Modal, Text, Button, Group, Stack } from '@mantine/core'
import { IconTruck } from '@tabler/icons-react'

interface Spawner {
  name: string
  label: string
  type: string
  job?: string
  gang?: string
  vehicles: Array<{ model: string; label: string }>
}

interface SpawnerViewProps {
  spawner: Spawner
  onClose: () => void
}

const SpawnerView = ({ spawner, onClose }: SpawnerViewProps) => {
  return (
    <Modal
      opened={true}
      onClose={onClose}
      title={
        <Group>
          <IconTruck size={24} color="var(--mantine-color-green-6)" />
          <Text size="xl" fw={600} c="green.6">
            {spawner.label}
          </Text>
        </Group>
      }
      size="lg"
    >
      <Stack gap="md">
        <Text>Vehicle spawner coming soon...</Text>
        <Text size="sm" c="dimmed">
          Type: {spawner.type} • Job: {spawner.job || 'N/A'} • Vehicles: {spawner.vehicles.length}
        </Text>
        <Button onClick={onClose}>Close</Button>
      </Stack>
    </Modal>
  )
}

export default SpawnerView