import React from 'react'
import { AuthWrapper } from './components/AuthWrapper'
import { TaskBoardContainer } from './components/TaskBoardContainer'
import { useRealtimeSubscription } from './hooks/useRealtimeSubscription'

const TaskBoardApp: React.FC = () => {
  useRealtimeSubscription()
  
  return <TaskBoardContainer />
}

function App() {
  return (
    <AuthWrapper>
      <TaskBoardApp />
    </AuthWrapper>
  )
}

export default App