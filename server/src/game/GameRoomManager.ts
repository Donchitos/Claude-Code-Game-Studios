import { Server } from 'socket.io';
import { GameMode, Player, PlayerInput } from '../shared';
import { v4 as uuidv4 } from 'uuid';
import { GameRoom } from './GameRoom';

export class GameRoomManager {
  private rooms = new Map<string, GameRoom>();
  private socketToRoom = new Map<string, string>(); // socketId → roomId

  createRoom(mode: GameMode, players: Player[]): GameRoom {
    const room = new GameRoom(uuidv4(), mode, players);
    this.rooms.set(room.id, room);
    for (const p of players) {
      this.socketToRoom.set(p.id, room.id);
    }
    return room;
  }

  applyInput(socketId: string, input: PlayerInput): void {
    const roomId = this.socketToRoom.get(socketId);
    if (roomId) this.rooms.get(roomId)?.applyInput(socketId, input);
  }

  handleDisconnect(socketId: string, io: Server): void {
    const roomId = this.socketToRoom.get(socketId);
    if (!roomId) return;
    this.rooms.get(roomId)?.handleDisconnect(socketId, io);
    this.socketToRoom.delete(socketId);
  }

  tick(io: Server): void {
    for (const [id, room] of this.rooms) {
      room.tick(io);
      if (room.isFinished) this.rooms.delete(id);
    }
  }

  get activeRoomCount(): number {
    return this.rooms.size;
  }
}
