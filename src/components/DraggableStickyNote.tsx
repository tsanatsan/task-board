import React, { useEffect, useRef } from 'react'
import { useDrag } from 'react-dnd'
import { getEmptyImage } from 'react-dnd-html5-backend'
import { StickyNote } from './StickyNote'
import { Task, DragItem } from '../types'

interface DraggableStickyNoteProps {
  task: Task
  onSelect: (task: Task) => void
}

export const DraggableStickyNote: React.FC<DraggableStickyNoteProps> = ({ 
  task, 
  onSelect 
}) => {
  const [{ isDragging }, drag, preview] = useDrag(() => ({
    type: 'task',
    item: (): DragItem => ({
      type: 'task',
      id: task.id,
      task
    }),
    collect: (monitor) => ({
      isDragging: monitor.isDragging(),
    }),
    // Enable smooth dragging without snapping
    options: {
      dropEffect: 'move',
    },
  }))

  // Hide the default drag preview
  useEffect(() => {
    preview(getEmptyImage(), { captureDraggingState: true })
  }, [])

  return (
    <div 
      ref={drag}
      style={{
        cursor: isDragging ? 'grabbing' : 'grab',
        opacity: isDragging ? 0.3 : 1, // Make original semi-transparent while dragging
        transition: isDragging ? 'none' : 'all 0.2s ease',
        transform: isDragging ? 'scale(0.95)' : 'none'
      }}
    >
      <StickyNote 
        task={task} 
        onSelect={onSelect} 
        isDragging={isDragging}
      />
    </div>
  )
}