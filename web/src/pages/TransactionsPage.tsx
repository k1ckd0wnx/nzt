import { Container, Title, Text, Group } from '@mantine/core'
import { IconReceipt } from '@tabler/icons-react'
import { useLocale } from '@/hooks/useLocale'

export function TransactionsPage() {
  const { t } = useLocale()
  
  return (
    <Container size="xl" py="xl">
      <Group gap="sm" mb="xl">
        <IconReceipt size={32} />
        <Title order={1} c="white" fw={700}>
          {t('transactions.title')}
        </Title>
      </Group>
      <Text c="gray.4" size="lg">
        {t('transactions.subtitle')}
      </Text>
    </Container>
  )
}