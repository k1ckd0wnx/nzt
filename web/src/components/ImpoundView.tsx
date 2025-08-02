import { Modal, Text, Button, Group, Stack } from '@mantine/core'
import { IconBuildingBank } from '@tabler/icons-react'

interface Impound {
  name: string
  label: string
  type: string
  retrieval_fee: number
  release_time: number
}

interface ImpoundViewProps {
  impound: Impound
  onClose: () => void
}

const ImpoundView = ({ impound, onClose }: ImpoundViewProps) => {
  return (
    <Modal
      opened={true}
      onClose={onClose}
      title={
        <Group>
          <IconBuildingBank size={24} color="var(--mantine-color-red-6)" />
          <Text size="xl" fw={600} c="red.6">
            {impound.label}
          </Text>
        </Group>
      }
      size="lg"
    >
      <Stack gap="md">
        <Text>Impound system coming soon...</Text>
        <Text size="sm" c="dimmed">
          Type: {impound.type} • Fee: ${impound.retrieval_fee} • Release Time: {impound.release_time} min
        </Text>
        <Button onClick={onClose}>Close</Button>
      </Stack>
    </Modal>
  )
}

export default ImpoundView