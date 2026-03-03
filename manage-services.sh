#!/usr/bin/env bash
set -euo pipefail

BACKEND_PID_FILE="/tmp/yapster-backend.pid"
FRONTEND_PID_FILE="/tmp/yapster-frontend.pid"

start_services() {
    echo "🚀 Starting services..."
    
    # Check if already running
    if [ -f "$BACKEND_PID_FILE" ] && kill -0 $(cat "$BACKEND_PID_FILE") 2>/dev/null; then
        echo "⚠️  Backend already running (PID: $(cat $BACKEND_PID_FILE))"
    else
        echo "🚀 Starting backend service..."
        cd backend
        npm run dev --silent &
        echo $! > "$BACKEND_PID_FILE"
        cd ..
        echo "✅ Backend started (PID: $(cat $BACKEND_PID_FILE))"
    fi
    
    if [ -f "$FRONTEND_PID_FILE" ] && kill -0 $(cat "$FRONTEND_PID_FILE") 2>/dev/null; then
        echo "⚠️  Frontend already running (PID: $(cat $FRONTEND_PID_FILE))"
    else
        echo "🚀 Starting frontend service..."
        cd frontend
        npm run dev --silent &
        echo $! > "$FRONTEND_PID_FILE"
        cd ..
        echo "✅ Frontend started (PID: $(cat $FRONTEND_PID_FILE))"
    fi
    
    # Wait for services to be ready
    echo "⏳ Waiting for services to be ready..."
    for i in {1..10}; do
        backend_ready=false
        frontend_ready=false
        
        if curl -fsS http://localhost:3000/health >/dev/null 2>&1; then
            backend_ready=true
        fi
        
        if curl -fsS http://localhost:5173/health >/dev/null 2>&1; then
            frontend_ready=true
        fi
        
        if [ "$backend_ready" = true ] && [ "$frontend_ready" = true ]; then
            echo "🎉 Both services are ready!"
            return 0
        fi
        
        sleep 1
    done
    
    echo "⚠️  Services started but may not be fully ready yet"
}

stop_services() {
    echo "🛑 Stopping services..."
    
    if [ -f "$BACKEND_PID_FILE" ]; then
        if kill -0 $(cat "$BACKEND_PID_FILE") 2>/dev/null; then
            kill $(cat "$BACKEND_PID_FILE") 2>/dev/null || true
            echo "✅ Backend stopped"
        fi
        rm -f "$BACKEND_PID_FILE"
    fi
    
    if [ -f "$FRONTEND_PID_FILE" ]; then
        if kill -0 $(cat "$FRONTEND_PID_FILE") 2>/dev/null; then
            kill $(cat "$FRONTEND_PID_FILE") 2>/dev/null || true
            echo "✅ Frontend stopped"
        fi
        rm -f "$FRONTEND_PID_FILE"
    fi
    
    # Cleanup any orphaned processes
    pkill -f "vite" 2>/dev/null || true
    pkill -f "ts-node-dev" 2>/dev/null || true
    
    echo "✅ Services stopped"
}

status_services() {
    echo "📊 Service status:"
    
    backend_running=false
    frontend_running=false
    
    if [ -f "$BACKEND_PID_FILE" ] && kill -0 $(cat "$BACKEND_PID_FILE") 2>/dev/null; then
        backend_running=true
        echo "  ✅ Backend running (PID: $(cat $BACKEND_PID_FILE))"
    else
        echo "  ❌ Backend not running"
    fi
    
    if [ -f "$FRONTEND_PID_FILE" ] && kill -0 $(cat "$FRONTEND_PID_FILE") 2>/dev/null; then
        frontend_running=true
        echo "  ✅ Frontend running (PID: $(cat $FRONTEND_PID_FILE))"
    else
        echo "  ❌ Frontend not running"
    fi
    
    if [ "$backend_running" = true ] && [ "$frontend_running" = true ]; then
        return 0
    else
        return 1
    fi
}

# Check if services are running (returns 0 if both running, 1 otherwise)
are_services_running() {
    if [ -f "$BACKEND_PID_FILE" ] && kill -0 $(cat "$BACKEND_PID_FILE") 2>/dev/null; then
        if [ -f "$FRONTEND_PID_FILE" ] && kill -0 $(cat "$FRONTEND_PID_FILE") 2>/dev/null; then
            return 0
        fi
    fi
    return 1
}

case "${1:-}" in
    start)
        start_services
        ;;
    stop)
        stop_services
        ;;
    status)
        status_services
        ;;
    restart)
        stop_services
        sleep 2
        start_services
        ;;
    check)
        # Silent check, just exit code
        are_services_running
        ;;
    *)
        echo "Usage: $0 {start|stop|status|restart|check}"
        echo ""
        echo "Commands:"
        echo "  start   - Start backend and frontend services"
        echo "  stop    - Stop backend and frontend services"
        echo "  status  - Show current status of services"
        echo "  restart - Restart both services"
        echo "  check   - Silent check (exit 0 if running, 1 if not)"
        exit 1
        ;;
esac
