import {
  Container,
  Grid,
  Card,
  Text,
  Title,
  Button,
  Group,
  Badge,
  Stack,
  Box,
  SimpleGrid,
  Flex,
  ThemeIcon,
  Progress,
  Divider,
  Paper
} from '@mantine/core'
import {
  IconDeviceGamepad,
  IconCircle,
  IconBomb,
  IconTrendingUp,
  IconTrophy,
  IconCoins,
  IconFlame,
  IconChartLine,
  IconStar,
  IconDeviceGamepad2
} from '@tabler/icons-react'
import { useAppStore } from '@/store/useAppStore'
import { motion } from 'framer-motion'

interface GameCard {
  id: string
  name: string
  description: string
  icon: React.ReactNode
  minBet: number
  color: string
  gradient: { from: string; to: string }
  isPopular?: boolean
  isNew?: boolean
}

export function LobbyPage() {
  const { setCurrentPage, user, config } = useAppStore()

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
      minimumFractionDigits: 0,
      maximumFractionDigits: 0,
    }).format(amount)
  }

  const gameCards: GameCard[] = [
    {
      id: 'slots',
      name: t('lobby.slot_machines'),
      description: t('lobby.slot_description'),
      icon: <IconDeviceGamepad size={32} />,
      minBet: config?.minBets.slots || 20,
      color: 'blue',
      gradient: { from: 'blue', to: 'blue' },
      isPopular: true,
    },
    {
      id: 'plinko',
      name: t('nav.plinko'),
      description: t('lobby.plinko_description'),
      icon: <IconCircle size={32} />,
      minBet: config?.minBets.plinko || 10,
      color: 'blue',
      gradient: { from: 'blue', to: 'blue' },
    },
    {
      id: 'mines',
      name: t('nav.mines'),
      description: t('lobby.mines_description'),
      icon: <IconBomb size={32} />,
      minBet: config?.minBets.mines || 10,
      color: 'blue',
      gradient: { from: 'blue', to: 'blue' },
      isNew: true,
    },
    {
      id: 'aviator',
      name: t('nav.aviator'),
      description: t('lobby.aviator_description'),
      icon: <IconTrendingUp size={32} />,
      minBet: config?.minBets.aviator || 10,
      color: 'blue',
      gradient: { from: 'blue', to: 'blue' },
      isPopular: true,
    },
  ]

  const userStats = [
    {
      label: t('lobby.total_wagered'),
      value: formatCurrency(user?.totalWagered || 0),
      icon: <IconCoins size={20} />,
      color: 'blue',
    },
    {
      label: t('lobby.total_won'),
      value: formatCurrency(user?.totalWon || 0),
      icon: <IconTrophy size={20} />,
      color: 'blue',
    },
    {
      label: t('lobby.win_rate'),
      value: user?.totalWagered && user?.totalWagered > 0 
        ? `${((user.totalWon || 0) / user.totalWagered * 100).toFixed(1)}%`
        : '0%',
      icon: <IconChartLine size={20} />,
      color: 'blue',
    },
    {
      label: t('lobby.level'),
      value: Math.floor((user?.totalWagered || 0) / 1000) + 1,
      icon: <IconStar size={20} />,
      color: 'blue',
    },
  ]

  const levelProgress = ((user?.totalWagered || 0) % 1000) / 1000 * 100

  return (
    <Container size="xl" py="xl">
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5 }}
      >
        <Stack gap="xl">
          {/* Welcome Section */}
          <div>
            <Group justify="space-between" align="flex-start" mb="lg">
              <div>
                <Title order={1} c="white" fw={700} mb="xs">
                  Welcome back, {user?.username}!
                </Title>
                <Text size="lg" c="gray.4">
                  Ready to play? Choose your game and start winning.
                </Text>
              </div>
              <Badge
                size="xl"
                variant="gradient"
                gradient={{ from: 'blue', to: 'cyan' }}
                leftSection={<IconFlame size={18} />}
              >
                Level {Math.floor((user?.totalWagered || 0) / 1000) + 1}
              </Badge>
            </Group>

            {/* Level Progress */}
            <Paper p="md" radius="md" className="glass" mb="xl">
              <Group justify="space-between" mb="xs">
                <Text size="sm" fw={500} c="white">
                  Level Progress
                </Text>
                <Text size="sm" c="gray.4">
                  {formatCurrency((user?.totalWagered || 0) % 1000)} / {formatCurrency(1000)}
                </Text>
              </Group>
              <Progress
                value={levelProgress}
                size="lg"
                radius="xl"
                color="blue"
                style={{
                  background: 'var(--mantine-color-dark-6)',
                }}
              />
            </Paper>
          </div>

          <Grid>
            {/* Games Section */}
            <Grid.Col span={{ base: 12, md: 8 }}>
              <Title order={2} c="white" mb="md" fw={600}>
                <Group gap="sm">
                  <IconDeviceGamepad2 size={28} />
                  Games
                </Group>
              </Title>

              <SimpleGrid cols={{ base: 1, sm: 2 }} spacing="lg">
                {gameCards.map((game, index) => (
                  <motion.div
                    key={game.id}
                    initial={{ opacity: 0, y: 20 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ duration: 0.5, delay: index * 0.1 }}
                    whileHover={{ y: -5 }}
                  >
                    <Card
                      shadow="lg"
                      radius="lg"
                      p="lg"
                      className="glass"
                      style={{
                        background: `linear-gradient(135deg, rgba(26, 31, 54, 0.9) 0%, rgba(${game.color === 'grape' ? '147, 51, 234' : game.color === 'orange' ? '251, 146, 60' : game.color === 'red' ? '239, 68, 68' : '34, 197, 94'}, 0.1) 100%)`,
                        border: `1px solid rgba(${game.color === 'grape' ? '147, 51, 234' : game.color === 'orange' ? '251, 146, 60' : game.color === 'red' ? '239, 68, 68' : '34, 197, 94'}, 0.3)`,
                        cursor: 'pointer',
                        position: 'relative',
                        overflow: 'hidden',
                      }}
                      onClick={() => setCurrentPage(game.id)}
                    >
                      {/* Badges */}
                      <div style={{ position: 'absolute', top: 12, right: 12, zIndex: 2 }}>
                        <Stack gap="xs">
                          {game.isPopular && (
                            <Badge color="yellow" variant="filled" size="sm">
                              {t('lobby.popular')}
                            </Badge>
                          )}
                          {game.isNew && (
                            <Badge color="green" variant="filled" size="sm">
                              {t('lobby.new')}
                            </Badge>
                          )}
                        </Stack>
                      </div>

                      <Group gap="md" mb="md">
                        <ThemeIcon
                          size="xl"
                          radius="md"
                          variant="gradient"
                          gradient={game.gradient}
                          className="glow-blue"
                        >
                          {game.icon}
                        </ThemeIcon>
                        <div style={{ flex: 1 }}>
                          <Text size="lg" fw={700} c="white">
                            {game.name}
                          </Text>
                          <Text size="sm" c="gray.4">
                            {game.description}
                          </Text>
                        </div>
                      </Group>

                      <Flex justify="space-between" align="center">
                        <Text size="sm" c="gray.4">
                          Min bet: {formatCurrency(game.minBet)}
                        </Text>
                        <Button
                          variant="gradient"
                          gradient={game.gradient}
                          size="sm"
                          className="btn-casino"
                        >
                          Play Now
                        </Button>
                      </Flex>

                      {/* Decorative elements */}
                      <Box
                        style={{
                          position: 'absolute',
                          bottom: -20,
                          right: -20,
                          width: 60,
                          height: 60,
                          borderRadius: '50%',
                          background: `radial-gradient(circle, rgba(${game.color === 'grape' ? '147, 51, 234' : game.color === 'orange' ? '251, 146, 60' : game.color === 'red' ? '239, 68, 68' : '34, 197, 94'}, 0.2) 0%, transparent 70%)`,
                          pointerEvents: 'none',
                        }}
                      />
                    </Card>
                  </motion.div>
                ))}
              </SimpleGrid>
            </Grid.Col>

            {/* Stats Section */}
            <Grid.Col span={{ base: 12, md: 4 }}>
              <Title order={2} c="white" mb="md" fw={600}>
                <Group gap="sm">
                  <IconChartLine size={28} />
                  Your Stats
                </Group>
              </Title>

              <Stack gap="md">
                {userStats.map((stat, index) => (
                  <motion.div
                    key={stat.label}
                    initial={{ opacity: 0, x: 20 }}
                    animate={{ opacity: 1, x: 0 }}
                    transition={{ duration: 0.5, delay: 0.3 + index * 0.1 }}
                  >
                    <Paper
                      p="md"
                      radius="md"
                      className="glass"
                      style={{
                        background: 'rgba(26, 31, 54, 0.6)',
                        border: '1px solid rgba(255, 255, 255, 0.1)',
                      }}
                    >
                      <Group gap="md">
                        <ThemeIcon
                          size="lg"
                          radius="md"
                          color={stat.color}
                          variant="light"
                        >
                          {stat.icon}
                        </ThemeIcon>
                        <div style={{ flex: 1 }}>
                          <Text size="xs" c="gray.5" tt="uppercase" fw={600}>
                            {stat.label}
                          </Text>
                          <Text size="lg" fw={700} c="white" className="count-up">
                            {stat.value}
                          </Text>
                        </div>
                      </Group>
                    </Paper>
                  </motion.div>
                ))}

                <Divider color="dark.4" />

                {/* Quick Actions */}
                <motion.div
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ duration: 0.5, delay: 0.7 }}
                >
                  <Title order={4} c="white" mb="md">
                    Quick Actions
                  </Title>
                  <Stack gap="sm">
                    <Button
                      variant="light"
                      color="teal"
                      fullWidth
                      leftSection={<IconCoins size={16} />}
                      onClick={() => setCurrentPage('banking')}
                      className="btn-casino"
                    >
                      Deposit Funds
                    </Button>
                    <Button
                      variant="subtle"
                      color="gray"
                      fullWidth
                      leftSection={<IconChartLine size={16} />}
                      onClick={() => setCurrentPage('transactions')}
                      className="btn-casino"
                    >
                      View History
                    </Button>
                  </Stack>
                </motion.div>
              </Stack>
            </Grid.Col>
          </Grid>
        </Stack>
      </motion.div>
    </Container>
  )
}