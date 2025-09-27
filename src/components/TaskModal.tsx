import React, { useState, useEffect } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { useTasksStore } from '../stores/tasks'
import { useUIStore } from '../stores/ui'
import { Priority } from '../types'

export const TaskModal: React.FC = () => {
  const { selectedTask, updateTask, deleteTask, createTask, selectTask } = useTasksStore()
  const { isTaskModalOpen, setTaskModalOpen } = useUIStore()
  
  const [title, setTitle] = useState('')
  const [description, setDescription] = useState('')
  const [priority, setPriority] = useState<Priority>('medium')
  const [isEditing, setIsEditing] = useState(false)

  const isOpen = selectedTask !== null || isTaskModalOpen
  const isNewTask = isTaskModalOpen && !selectedTask

  useEffect(() => {
    if (selectedTask) {
      setTitle(selectedTask.title)
      setDescription(selectedTask.description || '')
      setPriority(selectedTask.priority as Priority)
      setIsEditing(false)
    } else if (isTaskModalOpen) {
      // New task
      setTitle('')
      setDescription('')
      setPriority('medium')
      setIsEditing(true)
    }
  }, [selectedTask, isTaskModalOpen])

  const handleClose = () => {
    if (selectedTask) {
      selectTask(null)
    } else {
      setTaskModalOpen(false)
    }
    setIsEditing(false)
  }

  const handleSave = async () => {
    if (isNewTask) {
      // Create new task
      const x = Math.random() * (window.innerWidth - 300) + 50
      const y = Math.random() * (window.innerHeight - 250) + 50
      
      await createTask(title || 'New Task', { x, y }, priority)
      setTaskModalOpen(false)
    } else if (selectedTask) {
      // Update existing task
      await updateTask(selectedTask.id, {
        title: title || 'Untitled',
        description,
        priority
      })
      setIsEditing(false)
    }
  }

  const handleDelete = async () => {
    if (selectedTask && confirm('Are you sure you want to delete this task?')) {
      await deleteTask(selectedTask.id)
      selectTask(null)
    }
  }

  const priorityOptions = [
    { value: 'low' as Priority, label: 'Low Priority', color: 'bg-green-500', textColor: 'text-green-700' },
    { value: 'medium' as Priority, label: 'Medium Priority', color: 'bg-yellow-500', textColor: 'text-yellow-700' },
    { value: 'high' as Priority, label: 'High Priority', color: 'bg-red-500', textColor: 'text-red-700' }
  ]

  if (!isOpen) return null

  return (
    <AnimatePresence>
      <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
        {/* Backdrop */}
        <motion.div
          className="absolute inset-0 bg-black bg-opacity-50 backdrop-blur-sm"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          onClick={handleClose}
        />

        {/* Modal */}
        <motion.div
          className="relative bg-white rounded-2xl shadow-2xl max-w-md w-full max-h-[90vh] overflow-hidden"
          initial={{ scale: 0.8, opacity: 0, y: 50 }}
          animate={{ scale: 1, opacity: 1, y: 0 }}
          exit={{ scale: 0.8, opacity: 0, y: 50 }}
          transition={{ type: "spring", stiffness: 300, damping: 30 }}
        >
          {/* Header */}
          <div className="bg-gradient-to-r from-blue-500 to-purple-600 text-white p-6">
            <div className="flex items-center justify-between">
              <h2 className="text-xl font-semibold">
                {isNewTask ? 'Create New Task' : 'Task Details'}
              </h2>
              <button
                onClick={handleClose}
                className="text-white hover:text-gray-200 text-2xl leading-none"
              >
                ×
              </button>
            </div>
          </div>

          {/* Content */}
          <div className="p-6 space-y-6">
            {/* Title */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Title
              </label>
              {isEditing || isNewTask ? (
                <input
                  type="text"
                  value={title}
                  onChange={(e) => setTitle(e.target.value)}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                  placeholder="Enter task title..."
                  autoFocus
                />
              ) : (
                <p className="text-lg font-medium text-gray-900">{title}</p>
              )}
            </div>

            {/* Priority */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Priority
              </label>
              {isEditing || isNewTask ? (
                <div className="flex space-x-2">
                  {priorityOptions.map((option) => (
                    <button
                      key={option.value}
                      onClick={() => setPriority(option.value)}
                      className={`
                        flex items-center space-x-2 px-3 py-2 rounded-lg border-2 transition-all
                        ${priority === option.value
                          ? `border-gray-400 bg-gray-50 ${option.textColor}`
                          : 'border-gray-200 hover:border-gray-300'
                        }
                      `}
                    >
                      <div className={`w-3 h-3 rounded-full ${option.color}`} />
                      <span className="text-sm">{option.label.split(' ')[0]}</span>
                    </button>
                  ))}
                </div>
              ) : (
                <div className="flex items-center space-x-2">
                  <div className={`w-3 h-3 rounded-full ${
                    priority === 'high' ? 'bg-red-500' : 
                    priority === 'medium' ? 'bg-yellow-500' : 'bg-green-500'
                  }`} />
                  <span className="text-sm text-gray-600 capitalize">{priority} Priority</span>
                </div>
              )}
            </div>

            {/* Description */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Description
              </label>
              {isEditing || isNewTask ? (
                <textarea
                  value={description}
                  onChange={(e) => setDescription(e.target.value)}
                  rows={4}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 resize-none"
                  placeholder="Add a description..."
                />
              ) : (
                <p className="text-gray-600 whitespace-pre-wrap">
                  {description || 'No description provided.'}
                </p>
              )}
            </div>

            {/* Metadata for existing tasks */}
            {selectedTask && !isEditing && (
              <div className="text-sm text-gray-500 space-y-1">
                <p>Created: {new Date(selectedTask.created_at).toLocaleString()}</p>
                <p>Last updated: {new Date(selectedTask.updated_at).toLocaleString()}</p>
              </div>
            )}
          </div>

          {/* Actions */}
          <div className="bg-gray-50 px-6 py-4 flex justify-between">
            <div>
              {selectedTask && !isEditing && (
                <button
                  onClick={handleDelete}
                  className="px-4 py-2 text-red-600 hover:bg-red-50 rounded-lg transition-colors"
                >
                  Delete Task
                </button>
              )}
            </div>
            
            <div className="flex space-x-3">
              <button
                onClick={handleClose}
                className="px-4 py-2 text-gray-600 hover:bg-gray-100 rounded-lg transition-colors"
              >
                Cancel
              </button>
              
              {isEditing || isNewTask ? (
                <button
                  onClick={handleSave}
                  className="px-4 py-2 bg-blue-600 text-white hover:bg-blue-700 rounded-lg transition-colors"
                >
                  {isNewTask ? 'Create Task' : 'Save Changes'}
                </button>
              ) : (
                <button
                  onClick={() => setIsEditing(true)}
                  className="px-4 py-2 bg-blue-600 text-white hover:bg-blue-700 rounded-lg transition-colors"
                >
                  Edit Task
                </button>
              )}
            </div>
          </div>
        </motion.div>
      </div>
    </AnimatePresence>
  )
}