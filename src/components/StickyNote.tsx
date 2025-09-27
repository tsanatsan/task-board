import React from 'react'
import { motion } from 'framer-motion'
import { Task, Priority } from '../types'

interface StickyNoteProps {
  task: Task
  onSelect: (task: Task) => void
  isDragging?: boolean
}

const priorityClasses = {
  low: 'priority-low text-green-700',
  medium: 'priority-medium text-amber-700', 
  high: 'priority-high text-red-700'
}

export const StickyNote: React.FC<StickyNoteProps> = ({ 
  task, 
  onSelect, 
  isDragging = false 
}) => {
  const handleClick = () => {
    onSelect(task)
  }

  return (
    <motion.div
      className={`
        sticky-note ${priorityClasses[task.priority as Priority]}
        absolute cursor-pointer select-none
        ${isDragging ? 'z-50' : 'z-10'}
      `}
      style={{
        left: task.position_x,
        top: task.position_y,
        width: '200px',
        minHeight: '150px'
      }}
      onClick={handleClick}
      initial={{ scale: 0, rotate: -10, y: -20 }}
      animate={{ 
        scale: 1, 
        rotate: isDragging ? Math.random() * 6 - 3 : (Math.random() * 4 - 2), // Small random rotation even when not dragging
        y: 0
      }}
      transition={{ 
        type: "spring", 
        stiffness: 200, 
        damping: 20
      }}
      whileHover={{ 
        scale: 1.02,
        y: -3,
        transition: { duration: 0.2 }
      }}
      whileTap={{ scale: 0.98 }}
    >
      <div className="p-4 h-full flex flex-col relative z-10">
        {/* Adhesive strip effect */}
        <div className="absolute top-0 left-1/2 transform -translate-x-1/2 -translate-y-1 w-8 h-2 bg-gray-200 opacity-30 rounded-sm shadow-sm" />
        
        {/* Priority indicator */}
        <div className={`
          w-3 h-3 rounded-full mb-2 shadow-sm
          ${task.priority === 'high' ? 'bg-red-400' : ''}
          ${task.priority === 'medium' ? 'bg-amber-400' : ''}
          ${task.priority === 'low' ? 'bg-green-400' : ''}
        `} />
        
        {/* Task title */}
        <h3 className="font-medium text-sm mb-2 line-clamp-3 flex-grow font-handwriting">
          {task.title}
        </h3>
        
        {/* Task description preview */}
        {task.description && (
          <p className="text-xs opacity-70 line-clamp-2 font-handwriting">
            {task.description}
          </p>
        )}
        
        {/* Creation date */}
        <div className="text-xs opacity-50 mt-2 font-mono">
          {new Date(task.created_at).toLocaleDateString()}
        </div>
      </div>
      
      {/* Paper texture overlay */}
      <div className="absolute inset-0 pointer-events-none opacity-5">
        <div className="w-full h-full" style={{
          backgroundImage: `url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='20' height='20' viewBox='0 0 20 20'%3E%3Cg fill='%23000' fill-opacity='0.1'%3E%3Cpolygon points='10 0 20 10 10 20 0 10'/%3E%3C/g%3E%3C/svg%3E")`,
          backgroundSize: '20px 20px'
        }} />
      </div>
      
      {/* Corner fold effect */}
      <div className="absolute top-0 right-0 w-0 h-0 border-l-4 border-b-4 border-l-transparent border-b-black opacity-10" />
    </motion.div>
  )
}