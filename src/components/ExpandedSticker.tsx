import React, { useState, useEffect } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { Task, Priority } from '../types'
import { useTasksStore } from '../stores/tasks'

interface ExpandedStickerProps {
  task: Task | null
  originalPosition: { x: number; y: number }
  onClose: () => void
}

export const ExpandedSticker: React.FC<ExpandedStickerProps> = ({ task, originalPosition, onClose }) => {
  const { updateTask, deleteTask } = useTasksStore()
  const [title, setTitle] = useState('')
  const [description, setDescription] = useState('')
  const [priority, setPriority] = useState<Priority>('medium')

  useEffect(() => {
    if (task) {
      setTitle(task.title || '')
      setDescription(task.description || '')
      setPriority(task.priority)
    }
  }, [task])

  const isOpen = !!task

  const handleSave = async () => {
    if (!task) return
    
    await updateTask(task.id, {
      title: title || 'Untitled',
      description,
      priority
    })
    
    onClose()
  }

  const handleDelete = async () => {
    if (!task) return
    await deleteTask(task.id)
    onClose()
  }

  const handleClose = () => {
    onClose()
  }

  const getPriorityColor = (priority: string) => {
    switch (priority) {
      case 'low': return '#C8F7C5'
      case 'medium': return '#FFF2CC' 
      case 'high': return '#FFD5D5'
      default: return '#FFF2CC'
    }
  }

  const getPriorityBorder = (priority: string) => {
    switch (priority) {
      case 'low': return '#A8E8A1'
      case 'medium': return '#FFE588'
      case 'high': return '#FFC2C2'
      default: return '#FFE588'
    }
  }

  if (!isOpen || !task) return null

  return (
    <AnimatePresence>
      <div className="fixed inset-0 z-[10000] flex items-center justify-center">
        {/* Backdrop */}
        <motion.div
          className="absolute inset-0 bg-black/20 backdrop-blur-sm"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          onClick={handleClose}
        />

        {/* Expanded Sticker */}
        <motion.div
          className="relative"
          style={{
            backgroundColor: getPriorityColor(priority),
            border: `3px solid ${getPriorityBorder(priority)}`,
            borderRadius: '12px',
            padding: '24px',
            boxShadow: '0 20px 40px rgba(0,0,0,0.15), 0 8px 16px rgba(0,0,0,0.1)',
            userSelect: 'none'
          }}
          initial={{
            x: originalPosition.x - window.innerWidth / 2 + 100,
            y: originalPosition.y - window.innerHeight / 2 + 75,
            width: 200,
            height: 150,
            scale: 1,
            rotateX: 0,
            rotateY: 0
          }}
          animate={{
            x: 0,
            y: 0,
            width: 500,
            height: 400,
            scale: 1,
            rotateX: 0,
            rotateY: 0
          }}
          exit={{
            x: originalPosition.x - window.innerWidth / 2 + 100,
            y: originalPosition.y - window.innerHeight / 2 + 75,
            width: 200,
            height: 150,
            scale: 1
          }}
          transition={{
            type: "spring",
            stiffness: 300,
            damping: 30,
            duration: 0.4
          }}
        >
          {/* Close button */}
          <button
            onClick={handleClose}
            className="absolute top-3 right-3 w-8 h-8 rounded-full bg-gray-200 hover:bg-gray-300 flex items-center justify-center text-gray-600 font-bold transition-colors"
          >
            ×
          </button>

          {/* Priority selector */}
          <div className="flex gap-2 mb-4">
            {(['low', 'medium', 'high'] as Priority[]).map((p) => (
              <button
                key={p}
                onClick={() => setPriority(p)}
                className={`
                  w-6 h-6 rounded-full transition-all duration-200
                  ${priority === p ? 'ring-2 ring-gray-400 scale-110' : ''}
                `}
                style={{
                  backgroundColor: p === 'low' ? '#6BCF7F' : 
                                  p === 'medium' ? '#FFD93D' : '#FF6B6B'
                }}
              />
            ))}
          </div>

          {/* Title input */}
          <input
            type="text"
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            placeholder="Task title..."
            className="w-full text-xl font-semibold bg-transparent border-none outline-none mb-4 text-gray-800 placeholder-gray-500"
            style={{ fontFamily: 'Kalam, cursive' }}
            autoFocus
          />

          {/* Description textarea */}
          <textarea
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            placeholder="Add description..."
            className="w-full h-48 bg-transparent border-none outline-none resize-none text-gray-700 placeholder-gray-500 text-sm leading-relaxed"
            style={{ fontFamily: 'Kalam, cursive' }}
          />

          {/* Action buttons */}
          <div className="flex justify-between items-center mt-6">
            <button
              onClick={handleDelete}
              className="px-4 py-2 bg-red-500 hover:bg-red-600 text-white rounded-lg transition-colors font-medium"
            >
              Delete
            </button>
            
            <button
              onClick={handleSave}
              className="px-6 py-2 bg-blue-500 hover:bg-blue-600 text-white rounded-lg transition-colors font-medium"
            >
              Save
            </button>
          </div>
        </motion.div>
      </div>
    </AnimatePresence>
  )
}