import { useState, useRef, useEffect, useCallback } from 'react'
import {
  Container,
  Title,
  Text,
  Button,
  NumberInput,
  Group,
  Stack,
  Paper,
  Badge,
  Grid,
  Center,
  Box,
  ActionIcon,
  Tooltip
} from '@mantine/core'
import { IconPlayerPlay, IconMinus, IconPlus, IconCoins, IconTrophy } from '@tabler/icons-react'
import { useAppStore } from '@/store/useAppStore'
import { motion, AnimatePresence } from 'framer-motion'

interface Ball {
  id: number
  x: number
  y: number
  vx: number
  vy: number
  radius: number
  color: string
  trail: { x: number; y: number }[]
}

interface Peg {
  x: number
  y: number
  radius: number
}

const MULTIPLIERS = [1000, 130, 26, 9, 4, 2, 2, 4, 9, 26, 130, 1000]
const ROWS = 16
const PEG_RADIUS = 4
const BALL_RADIUS = 6
const GRAVITY = 0.3
const BOUNCE = 0.7
const FRICTION = 0.99

export function PlinkoPage() {
  const { user, sendNUIMessage } = useAppStore()
  const canvasRef = useRef<HTMLCanvasElement>(null)
  const animationFrameRef = useRef<number>()
  
  const [betAmount, setBetAmount] = useState(10)
  const [isPlaying, setIsPlaying] = useState(false)
  const [balls, setBalls] = useState<Ball[]>([])
  const [pegs, setPegs] = useState<Peg[]>([])
  const [lastWin, setLastWin] = useState<number | null>(null)
  const [ballCount, setBallCount] = useState(0)

  // Initialize pegs
  useEffect(() => {
    const newPegs: Peg[] = []
    const canvas = canvasRef.current
    if (!canvas) return

    const width = canvas.width
    const height = canvas.height
    const pegSpacing = width / (ROWS + 1)
    const rowHeight = (height - 200) / ROWS

    for (let row = 0; row < ROWS; row++) {
      const pegsInRow = row + 3
      const startX = (width - (pegsInRow - 1) * pegSpacing) / 2
      
      for (let col = 0; col < pegsInRow; col++) {
        newPegs.push({
          x: startX + col * pegSpacing,
          y: 100 + row * rowHeight,
          radius: PEG_RADIUS
        })
      }
    }
    
    setPegs(newPegs)
  }, [])

  // Animation loop
  useEffect(() => {
    const canvas = canvasRef.current
    const ctx = canvas?.getContext('2d')
    if (!canvas || !ctx) return

    const animate = () => {
      // Clear canvas
      ctx.fillStyle = 'rgba(12, 20, 38, 0.1)'
      ctx.fillRect(0, 0, canvas.width, canvas.height)

      // Draw pegs
      pegs.forEach(peg => {
        ctx.beginPath()
        ctx.arc(peg.x, peg.y, peg.radius, 0, Math.PI * 2)
        ctx.fillStyle = '#3b82f6'
        ctx.fill()
        ctx.strokeStyle = '#60a5fa'
        ctx.lineWidth = 1
        ctx.stroke()
      })

      // Draw multiplier zones
      const zoneWidth = canvas.width / MULTIPLIERS.length
      MULTIPLIERS.forEach((multiplier, index) => {
        const x = index * zoneWidth
        const y = canvas.height - 60
        
        // Zone background
        ctx.fillStyle = multiplier >= 100 ? 'rgba(34, 197, 94, 0.2)' : 
                       multiplier >= 10 ? 'rgba(59, 130, 246, 0.2)' : 
                       'rgba(156, 163, 175, 0.2)'
        ctx.fillRect(x, y, zoneWidth, 60)
        
        // Multiplier text
        ctx.fillStyle = multiplier >= 100 ? '#22c55e' : 
                       multiplier >= 10 ? '#3b82f6' : '#9ca3af'
        ctx.font = 'bold 12px Inter'
        ctx.textAlign = 'center'
        ctx.fillText(`${multiplier}x`, x + zoneWidth / 2, y + 35)
      })

      // Update and draw balls
      setBalls(prevBalls => {
        const updatedBalls = prevBalls.map(ball => {
          // Physics
          ball.vy += GRAVITY
          ball.x += ball.vx
          ball.y += ball.vy
          ball.vx *= FRICTION
          ball.vy *= FRICTION

          // Add to trail
          ball.trail.push({ x: ball.x, y: ball.y })
          if (ball.trail.length > 10) ball.trail.shift()

          // Collision with pegs
          pegs.forEach(peg => {
            const dx = ball.x - peg.x
            const dy = ball.y - peg.y
            const distance = Math.sqrt(dx * dx + dy * dy)
            
            if (distance < ball.radius + peg.radius) {
              const angle = Math.atan2(dy, dx)
              const targetX = peg.x + Math.cos(angle) * (peg.radius + ball.radius)
              const targetY = peg.y + Math.sin(angle) * (peg.radius + ball.radius)
              
              ball.x = targetX
              ball.y = targetY
              
              ball.vx = Math.cos(angle) * BOUNCE * 2 + (Math.random() - 0.5) * 0.5
              ball.vy = Math.sin(angle) * BOUNCE * 2
            }
          })

          // Wall collision
          if (ball.x < ball.radius || ball.x > canvas.width - ball.radius) {
            ball.vx *= -BOUNCE
            ball.x = ball.x < ball.radius ? ball.radius : canvas.width - ball.radius
          }

          // Check if ball reached bottom
          if (ball.y > canvas.height - 80) {
            const zoneIndex = Math.floor(ball.x / (canvas.width / MULTIPLIERS.length))
            const clampedIndex = Math.max(0, Math.min(MULTIPLIERS.length - 1, zoneIndex))
            const winAmount = betAmount * MULTIPLIERS[clampedIndex]
            
            setLastWin(winAmount)
            
            // Send result to server
            sendNUIMessage('plinkoResult', {
              betAmount,
              multiplier: MULTIPLIERS[clampedIndex],
              winAmount,
              ballId: ball.id
            })

            return null // Remove ball
          }

          return ball
        }).filter(Boolean) as Ball[]

        // Check if all balls are done
        if (prevBalls.length > 0 && updatedBalls.length === 0) {
          setIsPlaying(false)
        }

        return updatedBalls
      })

      // Draw balls
      balls.forEach(ball => {
        // Draw trail
        ctx.strokeStyle = ball.color + '40'
        ctx.lineWidth = 2
        ctx.beginPath()
        ball.trail.forEach((point, index) => {
          if (index === 0) {
            ctx.moveTo(point.x, point.y)
          } else {
            ctx.lineTo(point.x, point.y)
          }
        })
        ctx.stroke()

        // Draw ball
        ctx.beginPath()
        ctx.arc(ball.x, ball.y, ball.radius, 0, Math.PI * 2)
        ctx.fillStyle = ball.color
        ctx.fill()
        ctx.strokeStyle = '#ffffff'
        ctx.lineWidth = 2
        ctx.stroke()
      })

      animationFrameRef.current = requestAnimationFrame(animate)
    }

    animate()

    return () => {
      if (animationFrameRef.current) {
        cancelAnimationFrame(animationFrameRef.current)
      }
    }
  }, [balls, pegs, betAmount, sendNUIMessage])

  const dropBall = useCallback(() => {
    if (isPlaying || !user) return
    
    setIsPlaying(true)
    setLastWin(null)
    
    const canvas = canvasRef.current
    if (!canvas) return

    const newBall: Ball = {
      id: Date.now() + ballCount,
      x: canvas.width / 2 + (Math.random() - 0.5) * 20,
      y: 20,
      vx: (Math.random() - 0.5) * 0.5,
      vy: 0,
      radius: BALL_RADIUS,
      color: '#f59e0b',
      trail: []
    }

    setBalls([newBall])
    setBallCount(prev => prev + 1)

    // Send bet to server
    sendNUIMessage('plinkoBet', { betAmount })
  }, [isPlaying, user, betAmount, ballCount, sendNUIMessage])

  const adjustBet = (change: number) => {
    setBetAmount(prev => Math.max(10, Math.min(5000, prev + change)))
  }

  if (!user) {
    return (
      <Container size="xl" py="xl">
        <Center h="60vh">
          <Text c="dimmed">Please log in to play Plinko</Text>
        </Center>
      </Container>
    )
  }

  return (
    <Container size="xl" py="md">
      <Stack gap="md">
        {/* Header */}
        <Group justify="space-between" align="center">
          <div>
            <Title order={2} c="white" fw={700}>
              🔴 Plinko
            </Title>
            <Text c="dimmed" size="sm">
              Drop the ball and watch it bounce through the pegs!
            </Text>
          </div>
          <Group gap="md">
            <Text c="dimmed" size="sm">Balance:</Text>
            <Badge size="lg" color="blue" variant="filled">
              ${parseFloat(user.balance).toLocaleString()}
            </Badge>
          </Group>
        </Group>

        <Grid>
          {/* Game Controls */}
          <Grid.Col span={{ base: 12, md: 3 }}>
            <Paper p="md" bg="dark.7" radius="md">
              <Stack gap="md">
                <div>
                  <Text size="sm" c="dimmed" mb="xs">Bet Amount</Text>
                  <Group gap="xs">
                    <ActionIcon 
                      variant="filled" 
                      color="blue" 
                      onClick={() => adjustBet(-10)}
                      disabled={betAmount <= 10}
                    >
                      <IconMinus size={16} />
                    </ActionIcon>
                    <NumberInput
                      value={betAmount}
                      onChange={(value) => setBetAmount(Number(value) || 10)}
                      min={10}
                      max={5000}
                      size="sm"
                      styles={{ input: { textAlign: 'center' } }}
                      flex={1}
                    />
                    <ActionIcon 
                      variant="filled" 
                      color="blue" 
                      onClick={() => adjustBet(10)}
                      disabled={betAmount >= 5000}
                    >
                      <IconPlus size={16} />
                    </ActionIcon>
                  </Group>
                </div>

                <Group gap="xs">
                  <Button 
                    size="xs" 
                    variant="outline" 
                    onClick={() => setBetAmount(10)}
                  >
                    Min
                  </Button>
                  <Button 
                    size="xs" 
                    variant="outline" 
                    onClick={() => setBetAmount(Math.floor(parseFloat(user.balance) / 2))}
                  >
                    1/2
                  </Button>
                  <Button 
                    size="xs" 
                    variant="outline" 
                    onClick={() => setBetAmount(Math.floor(parseFloat(user.balance)))}
                  >
                    Max
                  </Button>
                </Group>

                <Button
                  fullWidth
                  size="lg"
                  onClick={dropBall}
                  disabled={isPlaying || betAmount > parseFloat(user.balance)}
                  leftSection={<IconPlayerPlay size={18} />}
                  gradient={{ from: 'blue', to: 'cyan' }}
                  variant="gradient"
                  className="btn-casino"
                >
                  {isPlaying ? 'Dropping...' : 'Drop Ball'}
                </Button>

                {lastWin && (
                  <motion.div
                    initial={{ scale: 0.8, opacity: 0 }}
                    animate={{ scale: 1, opacity: 1 }}
                    transition={{ duration: 0.3 }}
                  >
                    <Paper p="md" bg="green.8" radius="md">
                      <Group justify="center" gap="xs">
                        <IconTrophy size={20} color="#22c55e" />
                        <div>
                          <Text size="sm" c="green" ta="center">You Won!</Text>
                          <Text size="lg" fw={700} c="green" ta="center">
                            ${lastWin.toLocaleString()}
                          </Text>
                        </div>
                      </Group>
                    </Paper>
                  </motion.div>
                )}
              </Stack>
            </Paper>
          </Grid.Col>

          {/* Game Canvas */}
          <Grid.Col span={{ base: 12, md: 9 }}>
            <Paper p="md" bg="dark.8" radius="md" h="600">
              <canvas
                ref={canvasRef}
                width={600}
                height={580}
                style={{
                  width: '100%',
                  height: '100%',
                  background: 'linear-gradient(180deg, #0c1426 0%, #1a1f36 100%)',
                  borderRadius: '8px',
                  border: '1px solid #374151'
                }}
              />
            </Paper>
          </Grid.Col>
        </Grid>

        {/* Multiplier Info */}
        <Paper p="md" bg="dark.7" radius="md">
          <Group justify="center" gap="md">
            <Group gap="xs">
              <Box w={12} h={12} bg="green.6" style={{ borderRadius: '50%' }} />
              <Text size="sm" c="dimmed">High Risk (100x+)</Text>
            </Group>
            <Group gap="xs">
              <Box w={12} h={12} bg="blue.6" style={{ borderRadius: '50%' }} />
              <Text size="sm" c="dimmed">Medium Risk (10x+)</Text>
            </Group>
            <Group gap="xs">
              <Box w={12} h={12} bg="gray.6" style={{ borderRadius: '50%' }} />
              <Text size="sm" c="dimmed">Low Risk (2x-9x)</Text>
            </Group>
          </Group>
        </Paper>
      </Stack>
    </Container>
  )
}