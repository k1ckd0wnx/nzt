import { Modal, Text, Button, Group, Stack } from '@mantine/core'
import { IconSettings } from '@tabler/icons-react'

interface AdminPanelProps {
  onClose: () => void
}

const AdminPanel = ({ onClose }: AdminPanelProps) => {
  return (
    <Modal
      opened={true}
      onClose={onClose}
      title={
        <Group>
          <IconSettings size={24} color="var(--mantine-color-orange-6)" />
          <Text size="xl" fw={600} c="orange.6">
            Admin Panel
          </Text>
        </Group>
      }
      size="xl"
    >
      <Stack gap="md">
        <Text>Admin panel coming soon...</Text>
        <Text size="sm" c="dimmed">
          Manage garages, impounds, spawners, and vehicles
        </Text>
        <Button onClick={onClose}>Close</Button>
      </Stack>
    </Modal>
  )
}

export default AdminPanel