import { create } from 'zustand'

interface UIState {
  isControlPanelVisible: boolean
  isTaskModalOpen: boolean
  isDragging: boolean
  canvasZoom: number
  canvasOffset: { x: number; y: number }
  
  // Actions
  setControlPanelVisible: (visible: boolean) => void
  setTaskModalOpen: (open: boolean) => void
  setDragging: (dragging: boolean) => void
  setCanvasZoom: (zoom: number) => void
  setCanvasOffset: (offset: { x: number; y: number }) => void
  resetCanvas: () => void
}

export const useUIStore = create<UIState>((set) => ({
  isControlPanelVisible: false,
  isTaskModalOpen: false,
  isDragging: false,
  canvasZoom: 1,
  canvasOffset: { x: 0, y: 0 },

  setControlPanelVisible: (visible: boolean) => {
    set({ isControlPanelVisible: visible })
  },

  setTaskModalOpen: (open: boolean) => {
    set({ isTaskModalOpen: open })
  },

  setDragging: (dragging: boolean) => {
    set({ isDragging: dragging })
  },

  setCanvasZoom: (zoom: number) => {
    set({ canvasZoom: Math.max(0.5, Math.min(2, zoom)) })
  },

  setCanvasOffset: (offset: { x: number; y: number }) => {
    set({ canvasOffset: offset })
  },

  resetCanvas: () => {
    set({ canvasZoom: 1, canvasOffset: { x: 0, y: 0 } })
  },
}))