import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

// Lazy-load page components
const Home = () => import('@/views/Home.vue')
const Notes = () => import('@/views/Notes.vue')
const Flashcards = () => import('@/views/Flashcards.vue')
const MemoQuest = () => import('@/views/MemoQuest.vue')
const Decks = () => import('@/views/Decks.vue')
const Profile = () => import('@/views/Profile.vue')
const StudyGroups = () => import('@/views/StudyGroups.vue')
const PomodoroRooms = () => import('@/views/PomodoroRooms.vue')
const Analytics = () => import('@/views/Analytics.vue')

// Define routes
const routes = [
  {
    path: '/',
    name: 'Home',
    component: Home
  },
  {
    path: '/notes',
    name: 'Notes',
    component: Notes,
    meta: { requiresAuth: true }
  },
  {
    path: '/flashcards',
    name: 'Flashcards',
    component: Flashcards,
    meta: { requiresAuth: true }
  },
  {
    path: '/decks',
    name: 'Decks',
    component: Decks,
    meta: { requiresAuth: true }
  },
  {
    path: '/decks/:deckId',
    name: 'DeckDetails',
    component: Decks,
    meta: { requiresAuth: true }
  },
  {
    path: '/decks/:deckId/assignments',
    name: 'DeckAssignments',
    component: Decks,
    meta: { requiresAuth: true }
  },
  {
    path: '/decks/:deckId/assignments/:assignmentId',
    name: 'AssignmentDetails',
    component: Decks,
    meta: { requiresAuth: true }
  },
  {
    path: '/memoquest',
    name: 'MemoQuest',
    component: MemoQuest,
    meta: { requiresAuth: true }
  },
  {
    path: '/profile',
    name: 'Profile',
    component: Profile,
    meta: { requiresAuth: true }
  },
  {
    path: '/study-groups',
    name: 'StudyGroups',
    component: StudyGroups,
    meta: { requiresAuth: true }
  },
  {
    path: '/pomodoro-rooms',
    name: 'PomodoroRooms',
    component: PomodoroRooms,
    meta: { requiresAuth: true }
  },
  {
    path: '/pomodoro-rooms/:roomId',
    name: 'PomodoroRoomDetail',
    component: PomodoroRooms,
    meta: { requiresAuth: true }
  },
  {
    path: '/analytics',
    name: 'Analytics',
    component: Analytics,
    meta: { requiresAuth: true }
  }
]

// Create router
const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes
})

// Navigation guard
router.beforeEach((to, from, next) => {
  const authStore = useAuthStore()
  
  // Check if the route requires authentication
  if (to.matched.some(record => record.meta.requiresAuth)) {
    // If not authenticated, redirect to home
    if (!authStore.isAuthenticated) {
      next({ path: '/' })
    } else {
      next()
    }
  } else {
    next()
  }
})

export default router