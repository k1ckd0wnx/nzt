import { Container, Title, Text, Group } from '@mantine/core'
import { IconBomb } from '@tabler/icons-react'
import { useLocale } from '@/hooks/useLocale'

export function MinesPage() {
  const { t } = useLocale()
  
  return (
    <Container size="xl" py="xl">
      <Group gap="sm" mb="xl">
        <IconBomb size={32} />
        <Title order={1} c="white" fw={700}>
          {t('nav.mines')}
        </Title>
      </Group>
      <Text c="gray.4" size="lg">
        {t('lobby.mines_description')}
      </Text>
    </Container>
  )
}