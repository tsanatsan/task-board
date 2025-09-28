import React, { useState, useRef, useEffect } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { useUIStore } from '../stores/ui'
import { useTasksStore } from '../stores/tasks'
import { useAuthStore } from '../stores/auth'
import { Priority } from '../types'

export const ControlPanel: React.FC = () => {
  const { isControlPanelVisible, setTaskModalOpen, setControlPanelVisible } = useUIStore()
  const { createTask } = useTasksStore()
  const { signOut, user } = useAuthStore()
  const [showUserMenu, setShowUserMenu] = useState(false)
  const userMenuRef = useRef<HTMLDivElement>(null)

  const handleCreateTask = async (priority: Priority = 'medium') => {
    // Create task at a random position
    const x = Math.random() * (window.innerWidth - 300) + 50
    const y = Math.random() * (window.innerHeight - 250) + 50
    
    await createTask('New Task', { x, y }, priority)
  }

  const handleOpenTaskModal = () => {
    setTaskModalOpen(true)
  }

  const handleUserClick = () => {
    setShowUserMenu(!showUserMenu)
  }

  const handlePanelMouseEnter = () => {
    setControlPanelVisible(true)
  }

  const handlePanelMouseLeave = () => {
    setControlPanelVisible(false)
  }

  const controlButtons = [
    {
      icon: '🟩',  // Зеленый круг для low priority
      label: 'Create Low Priority Task',
      onClick: () => handleCreateTask('low'),
      color: 'bg-green-500 hover:bg-green-600'
    },
    {
      icon: '🟨',  // Желтый круг для medium priority
      label: 'Create Medium Priority Task',
      onClick: () => handleCreateTask('medium'),
      color: 'bg-yellow-500 hover:bg-yellow-600'
    },
    {
      icon: '🔴',  // Красный круг для high priority
      label: 'Create High Priority Task',
      onClick: () => handleCreateTask('high'),
      color: 'bg-red-500 hover:bg-red-600'
    },
    {
      icon: '📝',
      label: 'New Detailed Task',
      onClick: handleOpenTaskModal,
      color: 'bg-blue-500 hover:bg-blue-600'
    }
  ]

  // Создаем объединенный массив элементов панели
  const allPanelElements = [
    {
      type: 'user',
      component: (
        <div className="flex items-center relative" ref={userMenuRef}>
          <div 
            className="w-10 h-10 bg-gradient-to-r from-blue-500 to-purple-600 rounded-full flex items-center justify-center text-white text-lg font-bold shadow-lg border-2 border-white/20 cursor-pointer transform transition-all duration-200 hover:scale-110 active:scale-95"
            onClick={handleUserClick}
          >
            {user?.email?.charAt(0).toUpperCase()}
          </div>

          {/* User dropdown menu */}
          <AnimatePresence>
            {showUserMenu && (
              <motion.div
                className="absolute bottom-14 left-0 bg-white rounded-lg shadow-xl border border-gray-200 py-2 min-w-40 z-50"
                initial={{ scale: 0, y: 10, opacity: 0 }}
                animate={{ scale: 1, y: 0, opacity: 1 }}
                exit={{ scale: 0, y: 10, opacity: 0 }}
                transition={{ type: "spring", stiffness: 300, damping: 30 }}
              >
                <div className="px-3 py-2 border-b border-gray-100">
                  <div className="text-sm font-medium text-gray-900 truncate">
                    {user?.email}
                  </div>
                </div>
                
                <button
                  onClick={() => {
                    setShowUserMenu(false)
                    signOut()
                  }}
                  className="w-full px-3 py-2 text-left hover:bg-red-50 text-sm flex items-center space-x-2 text-red-600"
                >
                  <span>🚪</span>
                  <span>Sign Out</span>
                </button>
              </motion.div>
            )}
          </AnimatePresence>
        </div>
      )
    },
    ...controlButtons.map(button => ({
      type: 'button',
      component: (
        <button
          onClick={button.onClick}
          className={`
            w-12 h-12 rounded-2xl ${button.color} text-white 
            flex items-center justify-center text-lg
            transform transition-all duration-200
            hover:scale-110 active:scale-95
            shadow-lg hover:shadow-xl
          `}
          title={button.label}
        >
          {button.icon}
        </button>
      )
    }))
  ]

  // Handle clicks outside user menu to close it
  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (userMenuRef.current && !userMenuRef.current.contains(event.target as Node)) {
        setShowUserMenu(false)
      }
    }

    document.addEventListener('mousedown', handleClickOutside)
    return () => {
      document.removeEventListener('mousedown', handleClickOutside)
    }
  }, [])

  return (
    <AnimatePresence>
      {isControlPanelVisible && (
        <motion.div
          className="control-panel"
          initial={{ y: 100, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          exit={{ y: 100, opacity: 0 }}
          transition={{ type: "spring", stiffness: 300, damping: 30 }}
          onMouseEnter={handlePanelMouseEnter}
          onMouseLeave={handlePanelMouseLeave}
        >
          <div className="flex items-center space-x-3 relative">
            {/* Объединенные элементы панели */}
            {allPanelElements.map((element, index) => (
              <motion.div
                key={index}
                initial={{ scale: 0, y: 50 }}
                animate={{ scale: 1, y: 0 }}
                transition={{ delay: 0 }}
                className={element.type === 'user' ? 'mr-4' : ''}
              >
                {element.component}
              </motion.div>
            ))}
          </div>
        </motion.div>
      )}
    </AnimatePresence>
  )
}