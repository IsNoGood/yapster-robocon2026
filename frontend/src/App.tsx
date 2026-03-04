import { useEffect, useState } from 'react'
import './App.css'

interface Message {
  id: string
  text: string
  timestamp: string
}

function App() {
  const [messages, setMessages] = useState<Message[]>([])
  const [messageText, setMessageText] = useState<string>('')
  const [isPosting, setIsPosting] = useState<boolean>(false)

  useEffect(() => {
    fetchMessages()
  }, [])

  const fetchMessages = async () => {
    try {
      const resp = await fetch('/api/messages')
      const data = await resp.json()
      setMessages(data)
    } catch (err) {
      console.error('Failed to fetch messages:', err)
    }
  }

  const handlePostMessage = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!messageText.trim() || isPosting) return

    setIsPosting(true)
    try {
      const resp = await fetch('/api/messages', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ text: messageText })
      })

      if (resp.ok) {
        setMessageText('')
        await fetchMessages()
      } else {
        const error = await resp.json()
        alert(error.error || 'Failed to post message')
      }
    } catch (err) {
      console.error('Failed to post message:', err)
      alert('Failed to post message')
    } finally {
      setIsPosting(false)
    }
  }

  const formatTimestamp = (timestamp: string) => {
    const date = new Date(timestamp)
    return date.toLocaleString()
  }

  return (
    <div className="App">
      <div className="App-content">
        <header className="App-header">
          <h1>Yapster</h1>
          <p>Share your thoughts with the world</p>
        </header>

        {/* Message posting form */}
        <form onSubmit={handlePostMessage} className="message-form">
          <div>
            <textarea
              id="message-input"
              value={messageText}
              onChange={(e) => setMessageText(e.target.value)}
              placeholder="What's on your mind?"
              maxLength={280}
              rows={3}
            />
            <div className="char-count">
              {messageText.length}/280
            </div>
          </div>
          <button
            id="yap-button"
            type="submit"
            disabled={!messageText.trim() || isPosting}
          >
            {isPosting ? 'Posting...' : 'Yap!'}
          </button>
        </form>

        {/* Messages list */}
        <div className="messages-section">
          <h2>Yaps</h2>
          <div id="messages-list">
            {messages.length === 0 ? (
              <p className="empty-state">No yaps yet. Be the first to yap!</p>
            ) : (
              messages.map((message) => (
                <div
                  key={message.id}
                  className="message"
                  data-message-id={message.id}
                >
                  <div className="message-text">
                    {message.text}
                  </div>
                  <div className="message-timestamp">
                    {formatTimestamp(message.timestamp)}
                  </div>
                </div>
              ))
            )}
          </div>
        </div>
      </div>

      {/* RoboCon Footer */}
      <footer className="App-footer">
        <div className="footer-content">
          <span className="footer-text">RoboCon 2026 Special Edition</span>
          <img 
            src="/images/robocon-logo.png" 
            alt="RoboCon Logo" 
            className="footer-logo"
          />
        </div>
      </footer>
    </div>
  )
}

export default App
