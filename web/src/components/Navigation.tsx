import { useState } from 'react'
import {
  Group,
  Text,
  UnstyledButton,
  Tooltip,
  ActionIcon,
  Menu,
  Avatar,
  Indicator,
  Badge,
  Flex,
  Paper
} from '@mantine/core'
import {
  IconHome,
  IconDeviceGamepad,
  IconCircle,
  IconBomb,
  IconTrendingUp,
  IconWallet,
  IconReceipt,
  IconUser,
  IconLogout,
  IconChevronDown
} from '@tabler/icons-react'
import { useAppStore } from '@/store/useAppStore'
import { motion } from 'framer-motion'

interface NavItem {
  id: string
  label: string
  icon: React.ReactNode
  color?: string
}

const navigationItems: NavItem[] = [
  { id: 'lobby', label: 'Lobby', icon: <IconHome size={20} />, color: 'blue' },
  { id: 'slots', label: 'Slots', icon: <IconDeviceGamepad size={20} />, color: 'grape' },
  { id: 'plinko', label: 'Plinko', icon: <IconCircle size={20} />, color: 'orange' },
  { id: 'mines', label: 'Mines', icon: <IconBomb size={20} />, color: 'red' },
  { id: 'aviator', label: 'Aviator', icon: <IconTrendingUp size={20} />, color: 'green' },
  { id: 'banking', label: 'Banking', icon: <IconWallet size={20} />, color: 'teal' },
  { id: 'transactions', label: 'History', icon: <IconReceipt size={20} />, color: 'gray' },
]

export function Navigation() {
  const { user, currentPage, setCurrentPage, sendNUIMessage, config } = useAppStore()
  const [isMenuOpen, setIsMenuOpen] = useState(false)

  const handleLogout = async () => {
    try {
      await sendNUIMessage('logout')
    } catch (error) {
      console.error('Logout failed:', error)
    }
  }

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
      minimumFractionDigits: 0,
      maximumFractionDigits: 0,
    }).format(amount)
  }

  return (
    <Paper
      shadow="md"
      p="md"
      style={{
        borderRadius: 0,
        borderBottom: '1px solid var(--mantine-color-dark-4)',
        background: 'linear-gradient(135deg, rgba(26, 31, 54, 0.95) 0%, rgba(12, 20, 38, 0.95) 100%)',
        backdropFilter: 'blur(10px)',
      }}
    >
      <Flex justify="space-between" align="center">
        {/* Logo and Casino Name */}
        <Group gap="sm">
          <motion.div
            whileHover={{ scale: 1.05 }}
            whileTap={{ scale: 0.95 }}
          >
            <Badge
              size="lg"
              variant="gradient"
              gradient={{ from: 'blue', to: 'cyan' }}
              style={{ fontSize: '16px', fontWeight: 700 }}
            >
              {config?.casinoName || 'Premium Casino'}
            </Badge>
          </motion.div>
        </Group>

        {/* Navigation Items */}
        <Group gap="xs" visibleFrom="sm">
          {navigationItems.map((item) => (
            <Tooltip key={item.id} label={item.label} position="bottom">
              <motion.div
                whileHover={{ scale: 1.05 }}
                whileTap={{ scale: 0.95 }}
              >
                <UnstyledButton
                  onClick={() => setCurrentPage(item.id)}
                  p="sm"
                  style={{
                    borderRadius: 'var(--mantine-radius-md)',
                    backgroundColor: currentPage === item.id 
                      ? 'var(--mantine-color-blue-6)' 
                      : 'transparent',
                    color: currentPage === item.id 
                      ? 'white' 
                      : 'var(--mantine-color-gray-3)',
                    transition: 'all 0.2s ease',
                  }}
                  className={currentPage === item.id ? 'glow-blue' : ''}
                >
                  {item.icon}
                </UnstyledButton>
              </motion.div>
            </Tooltip>
          ))}
        </Group>

        {/* User Info and Menu */}
        <Group gap="md">
          {/* Balance Display */}
          <motion.div
            key={user?.balance}
            initial={{ scale: 1.1 }}
            animate={{ scale: 1 }}
            transition={{ duration: 0.2 }}
          >
            <Badge
              size="lg"
              variant="light"
              color="green"
              leftSection={<IconWallet size={16} />}
              style={{ fontSize: '14px' }}
              className="count-up"
            >
              {formatCurrency(user?.balance || 0)}
            </Badge>
          </motion.div>

          {/* User Menu */}
          <Menu
            shadow="lg"
            width={200}
            position="bottom-end"
            opened={isMenuOpen}
            onChange={setIsMenuOpen}
          >
            <Menu.Target>
              <motion.div
                whileHover={{ scale: 1.05 }}
                whileTap={{ scale: 0.95 }}
              >
                <UnstyledButton
                  p="xs"
                  style={{
                    borderRadius: 'var(--mantine-radius-md)',
                    border: '1px solid var(--mantine-color-dark-4)',
                    backgroundColor: isMenuOpen 
                      ? 'var(--mantine-color-dark-6)' 
                      : 'var(--mantine-color-dark-7)',
                    transition: 'all 0.2s ease',
                  }}
                >
                  <Group gap="xs">
                    <Avatar
                      size="sm"
                      color="blue"
                      radius="xl"
                    >
                      <IconUser size={16} />
                    </Avatar>
                    <Text size="sm" c="white" fw={500}>
                      {user?.username}
                    </Text>
                    <IconChevronDown
                      size={16}
                      style={{
                        transform: isMenuOpen ? 'rotate(180deg)' : 'rotate(0deg)',
                        transition: 'transform 0.2s ease',
                      }}
                    />
                  </Group>
                </UnstyledButton>
              </motion.div>
            </Menu.Target>

            <Menu.Dropdown>
              <Menu.Label>Account</Menu.Label>
              <Menu.Item
                leftSection={<IconUser size={16} />}
                onClick={() => setCurrentPage('profile')}
              >
                Profile
              </Menu.Item>
              <Menu.Item
                leftSection={<IconWallet size={16} />}
                onClick={() => setCurrentPage('banking')}
              >
                Banking
              </Menu.Item>
              <Menu.Item
                leftSection={<IconReceipt size={16} />}
                onClick={() => setCurrentPage('transactions')}
              >
                Transaction History
              </Menu.Item>
              
              <Menu.Divider />
              
              <Menu.Item
                leftSection={<IconLogout size={16} />}
                color="red"
                onClick={handleLogout}
              >
                Logout
              </Menu.Item>
            </Menu.Dropdown>
          </Menu>
        </Group>
      </Flex>

      {/* Mobile Navigation - Hidden on larger screens */}
      <Group gap="xs" hiddenFrom="sm" mt="md" justify="center">
        {navigationItems.map((item) => (
          <Tooltip key={item.id} label={item.label} position="top">
            <motion.div
              whileHover={{ scale: 1.05 }}
              whileTap={{ scale: 0.95 }}
            >
              <ActionIcon
                variant={currentPage === item.id ? 'filled' : 'subtle'}
                color={currentPage === item.id ? 'blue' : 'gray'}
                size="lg"
                onClick={() => setCurrentPage(item.id)}
                className={currentPage === item.id ? 'glow-blue' : ''}
              >
                {item.icon}
              </ActionIcon>
            </motion.div>
          </Tooltip>
        ))}
      </Group>
    </Paper>
  )
}