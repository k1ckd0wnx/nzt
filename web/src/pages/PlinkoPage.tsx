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
import { useLocale } from '@/hooks/useLocale'
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

const MULTIPLIERS = [100, 26, 9, 4, 2, 1.5, 1, 0.5, 0.2, 0.5, 1, 1.5, 2, 4, 9, 26, 100]
const ROWS = 10 // Further reduced for maximum performance
const PEG_RADIUS = 2.5
const BALL_RADIUS = 4
const GRAVITY = 0.5 // Faster falling for quicker games
const BOUNCE = 0.4 // Minimal bouncing
const FRICTION = 0.995 // Smooth movement
const CANVAS_WIDTH = 600
const CANVAS_HEIGHT = 400 // Optimized size
const MAX_TRAIL_LENGTH = 5 // Minimal trail for best performance

export function PlinkoPage() {
  const { user, sendNUIMessage } = useAppStore()
  const { t, isInitialized } = useLocale()
  const canvasRef = useRef<HTMLCanvasElement>(null)
  const animationFrameRef = useRef<number>()
  
  const [betAmount, setBetAmount] = useState(10)
  const [isPlaying, setIsPlaying] = useState(false)
  const [balls, setBalls] = useState<Ball[]>([])
  const [pegs, setPegs] = useState<Peg[]>([])
  const [lastWin, setLastWin] = useState<number | null>(null)
  const [ballCount, setBallCount] = useState(0)

  // Initialize pegs with optimized distribution
  useEffect(() => {
    const newPegs: Peg[] = []
    const width = CANVAS_WIDTH
    const height = CANVAS_HEIGHT
    const pegSpacing = width / (ROWS + 2)
    const rowHeight = (height - 140) / ROWS // Adjusted for new height

    for (let row = 0; row < ROWS; row++) {
      const pegsInRow = row + 3
      const startX = (width - (pegsInRow - 1) * pegSpacing) / 2
      
      for (let col = 0; col < pegsInRow; col++) {
        newPegs.push({
          x: startX + col * pegSpacing,
          y: 60 + row * rowHeight, // Adjusted starting position
          radius: PEG_RADIUS
        })
      }
    }
    
    setPegs(newPegs)
  }, [])

  // Enhanced animation loop with better graphics
  useEffect(() => {
    const canvas = canvasRef.current
    const ctx = canvas?.getContext('2d')
    if (!canvas || !ctx) return

    // Maximize performance settings
    ctx.imageSmoothingEnabled = false
    
    const animate = () => {
      // Fast clear with solid color (no gradient for performance)
      ctx.fillStyle = '#0f172a'
      ctx.fillRect(0, 0, canvas.width, canvas.height)

        // Draw optimized pegs (no gradients/shadows for maximum performance)
        ctx.fillStyle = '#0ea5e9'
        ctx.strokeStyle = '#ffffff'
        ctx.lineWidth = 1
        pegs.forEach(peg => {
          ctx.beginPath()
          ctx.arc(peg.x, peg.y, peg.radius, 0, Math.PI * 2)
          ctx.fill()
          ctx.stroke()
        })

        // Draw optimized multiplier zones (solid colors for performance)
        const zoneWidth = canvas.width / MULTIPLIERS.length
        ctx.font = 'bold 12px Arial'
        ctx.textAlign = 'center'
        ctx.textBaseline = 'middle'
        
        MULTIPLIERS.forEach((multiplier, index) => {
          const x = index * zoneWidth
          const y = canvas.height - 50
          
          // Simple solid colors based on multiplier
          if (multiplier >= 100) {
            ctx.fillStyle = 'rgba(14, 165, 233, 0.6)'
            ctx.strokeStyle = '#0ea5e9'
          } else if (multiplier >= 10) {
            ctx.fillStyle = 'rgba(14, 165, 233, 0.3)'
            ctx.strokeStyle = '#0ea5e9'
          } else {
            ctx.fillStyle = 'rgba(71, 85, 105, 0.4)'
            ctx.strokeStyle = '#ffffff'
          }
          
          // Draw zone
          ctx.fillRect(x, y, zoneWidth, 50)
          ctx.lineWidth = 1
          ctx.strokeRect(x, y, zoneWidth, 50)
          
          // Draw text
          ctx.fillStyle = multiplier >= 10 ? '#0ea5e9' : '#ffffff'
          ctx.fillText(`${multiplier}x`, x + zoneWidth / 2, y + 25)
        })

      // Update and draw balls with enhanced physics
      setBalls(prevBalls => {
        const updatedBalls = prevBalls.map(ball => {
          // Enhanced physics
          ball.vy += GRAVITY
          ball.x += ball.vx
          ball.y += ball.vy
          ball.vx *= FRICTION
          ball.vy *= FRICTION

          // Add to trail with optimized length
          ball.trail.push({ x: ball.x, y: ball.y })
          if (ball.trail.length > MAX_TRAIL_LENGTH) ball.trail.shift()

          // Optimized collision with pegs (only check nearby pegs)
          pegs.forEach(peg => {
            // Quick distance check to avoid expensive calculations
            const dx = ball.x - peg.x
            const dy = ball.y - peg.y
            
            // Skip if peg is too far away
            if (Math.abs(dx) > 15 || Math.abs(dy) > 15) return
            
            const distance = Math.sqrt(dx * dx + dy * dy)
            
            if (distance < ball.radius + peg.radius) {
              const angle = Math.atan2(dy, dx)
              const targetX = peg.x + Math.cos(angle) * (peg.radius + ball.radius)
              const targetY = peg.y + Math.sin(angle) * (peg.radius + ball.radius)
              
              ball.x = targetX
              ball.y = targetY
              
              // Simplified bounce for better performance
              const bounceStrength = BOUNCE * (0.9 + Math.random() * 0.2)
              ball.vx = Math.cos(angle) * bounceStrength * 2.5 + (Math.random() - 0.5) * 0.6
              ball.vy = Math.sin(angle) * bounceStrength * 2.5 + Math.random() * 0.3
            }
          })

          // Enhanced wall collision
          if (ball.x < ball.radius || ball.x > canvas.width - ball.radius) {
            ball.vx *= -BOUNCE
            ball.x = ball.x < ball.radius ? ball.radius : canvas.width - ball.radius
            // Add some vertical randomness on wall hits
            ball.vy += (Math.random() - 0.5) * 0.3
          }

          // Check if ball reached bottom (optimized detection)
          if (ball.y > canvas.height - 70) {
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

              // Draw optimized balls with trails - blue and white theme
        balls.forEach(ball => {
          // Draw simplified trail for better performance
          if (ball.trail.length > 1) {
            ctx.strokeStyle = '#0ea5e9'
            ctx.lineWidth = 2 // Reduced for performance
            ctx.globalAlpha = 0.4 // Fixed alpha for better performance
            
            ctx.beginPath()
            ctx.moveTo(ball.trail[0].x, ball.trail[0].y)
            for (let i = 1; i < ball.trail.length; i++) {
              ctx.lineTo(ball.trail[i].x, ball.trail[i].y)
            }
            ctx.stroke()
            ctx.globalAlpha = 1
          }

          // Draw optimized ball (solid color for performance)
          ctx.fillStyle = '#0ea5e9'
          ctx.strokeStyle = '#ffffff'
          ctx.lineWidth = 1
          
          ctx.beginPath()
          ctx.arc(ball.x, ball.y, ball.radius, 0, Math.PI * 2)
          ctx.fill()
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

    const newBall: Ball = {
      id: Date.now() + ballCount,
      x: CANVAS_WIDTH / 2 + (Math.random() - 0.5) * 20, // Reduced randomness for faster gameplay
      y: 10,
      vx: (Math.random() - 0.5) * 0.2, // Reduced initial horizontal velocity
      vy: 0.3, // Increased initial downward velocity
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
              🔴 {isInitialized ? t('plinko.title') : 'Plinko'}
            </Title>
            <Text c="dimmed" size="sm">
              {isInitialized ? t('plinko.subtitle') : 'Drop the ball and watch it bounce through the pegs!'}
            </Text>
          </div>
          <Group gap="md">
            <Text c="dimmed" size="sm">{isInitialized ? t('nav.balance') : 'Balance'}:</Text>
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
                  <Text size="sm" c="dimmed" mb="xs">{isInitialized ? t('games.bet_amount') : 'Bet Amount'}</Text>
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
                  {isPlaying ? 
                    (isInitialized ? t('plinko.dropping') : 'Dropping...') : 
                    (isInitialized ? t('games.drop_ball') : 'Drop Ball')
                  }
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
            <Paper p="md" bg="dark.8" radius="md" h="540">
              <canvas
                ref={canvasRef}
                width={CANVAS_WIDTH}
                height={CANVAS_HEIGHT}
                style={{
                  width: '100%',
                  height: '100%',
                  background: 'linear-gradient(180deg, #0c1426 0%, #1a1f36 100%)',
                  borderRadius: '8px',
                  border: '2px solid #374151',
                  boxShadow: '0 8px 32px rgba(0, 0, 0, 0.4)'
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