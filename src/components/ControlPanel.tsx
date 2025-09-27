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
  const [showPriorityMenu, setShowPriorityMenu] = useState(false)
  const [showUserMenu, setShowUserMenu] = useState(false)
  const userMenuRef = useRef<HTMLDivElement>(null)

  const handleCreateTask = async (priority: Priority = 'medium') => {
    // Create task at a random position
    const x = Math.random() * (window.innerWidth - 300) + 50
    const y = Math.random() * (window.innerHeight - 250) + 50
    
    await createTask('New Task', { x, y }, priority)
    setShowPriorityMenu(false)
  }

  const handleOpenTaskModal = () => {
    setTaskModalOpen(true)
  }

  const handlePanelMouseEnter = () => {
    setControlPanelVisible(true)
  }

  const handlePanelMouseLeave = () => {
    setControlPanelVisible(false)
  }

  const controlButtons = [
    {
      icon: '➕',
      label: 'Create Task',
      onClick: () => setShowPriorityMenu(!showPriorityMenu),
      color: 'bg-green-500 hover:bg-green-600'
    },
    {
      icon: '📝',
      label: 'New Detailed Task',
      onClick: handleOpenTaskModal,
      color: 'bg-blue-500 hover:bg-blue-600'
    },
    {
      icon: '👤',
      label: 'Profile',
      onClick: () => {},
      color: 'bg-purple-500 hover:bg-purple-600'
    }
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

  const handleUserClick = () => {
    setShowUserMenu(!showUserMenu)
  }

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
            {/* User avatar with dropdown */}
            <div className="flex items-center mr-4 relative" ref={userMenuRef}>
              <motion.div 
                className="w-10 h-10 bg-gradient-to-r from-blue-500 to-purple-600 rounded-full flex items-center justify-center text-white text-lg font-bold shadow-lg border-2 border-white/20 cursor-pointer"
                whileHover={{ scale: 1.1 }}
                whileTap={{ scale: 0.95 }}
                onClick={handleUserClick}
              >
                {user?.email?.charAt(0).toUpperCase()}
              </motion.div>

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

            {/* Control buttons */}
            {controlButtons.map((button, index) => (
              <motion.button
                key={button.label}
                onClick={button.onClick}
                className={`
                  w-12 h-12 rounded-2xl ${button.color} text-white 
                  flex items-center justify-center text-lg
                  transform transition-all duration-200
                  hover:scale-110 active:scale-95
                  shadow-lg hover:shadow-xl
                `}
                whileHover={{ y: -5 }}
                whileTap={{ scale: 0.9 }}
                initial={{ scale: 0, y: 50 }}
                animate={{ scale: 1, y: 0 }}
                transition={{ delay: index * 0.1 }}
                title={button.label}
              >
                {button.icon}
              </motion.button>
            ))}

            {/* Priority menu for create task */}
            <AnimatePresence>
              {showPriorityMenu && (
                <motion.div
                  className="absolute bottom-16 left-0 bg-white rounded-lg shadow-xl border border-gray-200 py-2 min-w-32"
                  initial={{ scale: 0, y: 10 }}
                  animate={{ scale: 1, y: 0 }}
                  exit={{ scale: 0, y: 10 }}
                  transition={{ type: "spring", stiffness: 300, damping: 30 }}
                >
                  <div className="px-3 py-1 text-xs font-medium text-gray-500 uppercase tracking-wide">
                    Priority
                  </div>
                  
                  <button
                    onClick={() => handleCreateTask('low')}
                    className="w-full px-3 py-2 text-left hover:bg-green-50 text-sm flex items-center space-x-2"
                  >
                    <div className="w-3 h-3 bg-green-500 rounded-full"></div>
                    <span>Low</span>
                  </button>
                  
                  <button
                    onClick={() => handleCreateTask('medium')}
                    className="w-full px-3 py-2 text-left hover:bg-yellow-50 text-sm flex items-center space-x-2"
                  >
                    <div className="w-3 h-3 bg-yellow-500 rounded-full"></div>
                    <span>Medium</span>
                  </button>
                  
                  <button
                    onClick={() => handleCreateTask('high')}
                    className="w-full px-3 py-2 text-left hover:bg-red-50 text-sm flex items-center space-x-2"
                  >
                    <div className="w-3 h-3 bg-red-500 rounded-full"></div>
                    <span>High</span>
                  </button>
                </motion.div>
              )}
            </AnimatePresence>
          </div>
        </motion.div>
      )}
    </AnimatePresence>
  )
}