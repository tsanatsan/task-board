import React, { useState, useEffect } from 'react'
import { useTasksStore } from '../stores/tasks'
import { Task } from '../types'

interface StickerComponentProps {
  task: Task
  onSelect: (task: Task) => void
}

const StickerComponent: React.FC<StickerComponentProps> = ({ task, onSelect }) => {
  const [isDragging, setIsDragging] = useState(false)
  const [hasDragged, setHasDragged] = useState(false)
  const [dragOffset, setDragOffset] = useState({ x: 0, y: 0 })
  const [position, setPosition] = useState({ x: task.position_x, y: task.position_y })
  const { updateTaskPosition } = useTasksStore()

  // Sync position with task updates
  useEffect(() => {
    if (!isDragging) {
      setPosition({ x: task.position_x, y: task.position_y })
    }
  }, [task.position_x, task.position_y, isDragging])

  const handleMouseDown = (e: React.MouseEvent) => {
    e.preventDefault()
    e.stopPropagation()
    
    const rect = e.currentTarget.getBoundingClientRect()
    const offset = {
      x: e.clientX - rect.left,
      y: e.clientY - rect.top
    }
    
    setDragOffset(offset)
    setIsDragging(true)
    setHasDragged(false) // Сбрасываем флаг перетаскивания

    const handleMouseMove = (e: MouseEvent) => {
      setHasDragged(true) // Отмечаем, что было перетаскивание
      
      const stickerWidth = 200
      const stickerHeight = 150
      const maxX = window.innerWidth - stickerWidth
      const maxY = window.innerHeight - stickerHeight
      
      let newX = e.clientX - offset.x
      let newY = e.clientY - offset.y
      
      // Constrain to screen bounds
      newX = Math.max(0, Math.min(newX, maxX))
      newY = Math.max(0, Math.min(newY, maxY))
      
      setPosition({ x: newX, y: newY })
    }

    const handleMouseUp = () => {
      setIsDragging(false)
      if (hasDragged) {
        updateTaskPosition(task.id, position)
        // Очищаем флаг через короткое время, чтобы предотвратить клик
        setTimeout(() => setHasDragged(false), 100)
      }
      document.removeEventListener('mousemove', handleMouseMove)
      document.removeEventListener('mouseup', handleMouseUp)
    }

    document.addEventListener('mousemove', handleMouseMove)
    document.addEventListener('mouseup', handleMouseUp)
  }

  const handleClick = (e: React.MouseEvent) => {
    // Открываем только при обычном клике, а не после drag
    if (!hasDragged) {
      e.stopPropagation()
      onSelect(task)
    }
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

  return (
    <div
      style={{
        position: 'absolute',
        left: position.x,
        top: position.y,
        width: 200,
        height: 150,
        backgroundColor: getPriorityColor(task.priority),
        border: `2px solid ${getPriorityBorder(task.priority)}`,
        borderRadius: '8px',
        padding: '12px',
        cursor: isDragging ? 'grabbing' : 'grab',
        userSelect: 'none',
        boxShadow: isDragging 
          ? '0 8px 25px rgba(0,0,0,0.15)' 
          : '0 4px 12px rgba(0,0,0,0.1)',
        transform: isDragging ? 'rotate(2deg) scale(1.02)' : 'rotate(0deg) scale(1)',
        transition: isDragging ? 'none' : 'transform 0.2s ease, box-shadow 0.2s ease',
        zIndex: isDragging ? 1000 : 1
      }}
      onMouseDown={handleMouseDown}
      onClick={handleClick}
    >
      {/* Priority indicator */}
      <div
        style={{
          width: 12,
          height: 12,
          borderRadius: '50%',
          backgroundColor: task.priority === 'high' ? '#FF6B6B' : 
                          task.priority === 'medium' ? '#FFD93D' : '#6BCF7F',
          marginBottom: 8
        }}
      />
      
      {/* Task content */}
      <div style={{ 
        fontSize: '14px', 
        fontWeight: '500',
        color: '#2D3748',
        lineHeight: '1.4',
        marginBottom: '8px'
      }}>
        {task.title}
      </div>
      
      {task.description && (
        <div style={{
          fontSize: '12px',
          color: '#4A5568',
          lineHeight: '1.3',
          opacity: 0.8
        }}>
          {task.description.substring(0, 80)}...
        </div>
      )}
    </div>
  )
}

export const TaskBoard: React.FC = () => {
  const { tasks, selectTask, fetchTasks } = useTasksStore()

  useEffect(() => {
    fetchTasks()
  }, [fetchTasks])

  const handleBoardClick = () => {
    selectTask(null)
  }

  return (
    <div
      style={{
        width: '100vw',
        height: '100vh',
        background: 'linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%)',
        position: 'relative',
        overflow: 'hidden'
      }}
      onClick={handleBoardClick}
    >
      {/* Render all stickers */}
      {tasks.map((task) => (
        <StickerComponent
          key={task.id}
          task={task}
          onSelect={selectTask}
        />
      ))}
      
      {/* Empty state */}
      {tasks.length === 0 && (
        <div style={{
          position: 'absolute',
          top: '50%',
          left: '50%',
          transform: 'translate(-50%, -50%)',
          textAlign: 'center',
          color: '#718096'
        }}>
          <div style={{ fontSize: '48px', marginBottom: '16px' }}>📝</div>
          <h3 style={{ fontSize: '20px', fontWeight: '600', marginBottom: '8px' }}>
            No tasks yet
          </h3>
          <p style={{ fontSize: '14px' }}>
            Create your first sticky note task!
          </p>
        </div>
      )}
    </div>
  )
}