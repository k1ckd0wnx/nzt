import { Container, Title, Text, Group } from '@mantine/core'
import { IconReceipt } from '@tabler/icons-react'

export function TransactionsPage() {
  return (
    <Container size="xl" py="xl">
      <Group gap="sm" mb="xl">
        <IconReceipt size={32} />
        <Title order={1} c="white" fw={700}>
          Transaction History
        </Title>
      </Group>
      <Text c="gray.4" size="lg">
        Transaction history coming soon...
      </Text>
    </Container>
  )
}