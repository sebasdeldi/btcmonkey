# Testing Guide: Anti-Cheat Refresh Protection

## Quick Test Steps

### Test 1: Back Button Protection ✓

1. Start a game run
2. Wait for the 3-second countdown to finish and game to start
3. Click a few numbers
4. **Press the browser back button**
5. **Expected:** Black modal appears with warning message
6. Click "Cancel - Resume Game" → Timer should resume, game continues
7. Try back button again
8. Click "Exit - Forfeit Game" → Redirects to My Games with 1,999,999ms score

### Test 2: Keyboard Refresh Protection ✓

1. Start a new game run
2. Wait for game to start
3. Click a few numbers
4. **Press Ctrl+R (or Cmd+R on Mac)**
5. **Expected:** Black modal appears, refresh is prevented
6. Click "Cancel" → Game resumes
7. Try F5 key
8. **Expected:** Modal appears again
9. Click "Exit - Forfeit Game"
10. **Expected:** Redirects to My Games, game shows 1,999,999ms score

### Test 2b: Browser Refresh Button ✓

1. Start a new game run
2. Wait for game to start
3. Click a few numbers
4. **Click browser refresh button** (circular arrow icon)
5. **Expected:** Browser shows "Changes you made may not be saved" dialog
6. Click "Cancel" or "Stay" → Page stays, game continues
7. Try refresh button again
8. **This time click "Leave"**
9. **Expected:**
   - Page refreshes
   - Game is auto-forfeited
   - User redirected to My Games
   - Game shows 1,999,999ms score

### Test 3: Navigation to Other Pages ✓

#### Test 3a: Click Navigation Links

1. Start a new game run
2. Wait for game to start
3. Click a few numbers
4. **Click on "Buy Credits", "Sign Out", or any other navigation link**
5. **Expected:** Custom black modal appears
6. Click "Cancel - Resume Game" → Game continues
7. Try again and click "Exit - Forfeit Game" → Redirects to My Games with 1,999,999ms score

#### Test 3b: Type New URL in Address Bar

1. Start a new game run
2. Wait for game to start
3. Click a few numbers
4. **Type a new URL in address bar and press Enter**
5. **Expected:** Browser shows "Leave site?" dialog
6. If user leaves → Game auto-forfeits when they return

#### Test 3c: Close Tab/Window

1. Start a new game run
2. Wait for game to start
3. Click a few numbers
4. **Try to close the tab (Ctrl+W / Cmd+W) or close window**
5. **Expected:** Browser shows "Leave site?" dialog
6. Click "Cancel" → Tab stays open, game continues
7. Click "Leave" → Tab closes, game forfeited

#### Test 3d: Navigate to External Website

1. Start a new game run
2. Wait for game to start
3. Click a few numbers
4. **Type "google.com" in address bar and press Enter**
5. **Expected:** Browser shows "Leave site?" dialog
6. If user leaves → Game auto-forfeits when they return to the site

### Test 4: Normal Game Completion (No Interference) ✓

1. Start a new game run
2. Complete all 25 numbers
3. Wait for completion screen
4. **Try refresh, back button, or click any navigation link**
5. **Expected:** NO warnings, can navigate freely anywhere

### Test 5: Before Game Starts (No Protection) ✓

1. Navigate to a game run
2. **During the 3-second countdown, try back button or any navigation**
3. **Expected:** NO warnings, can go back/navigate freely
4. Game hasn't started yet, so no protection needed

## Verifying Forfeit Score

After forfeiting a game:

1. Go to "My Games" page
2. Find the session you forfeited
3. **Expected score:** 1,999,999ms (not 1,999,999ms)
4. **Status:** Played (cannot retry)
5. Check in Rails console:
   ```ruby
   GameRun.last
   # => score: 99999
   # => result_metadata: { forfeited: true, reason: "...", forfeited_at: "..." }
   ```

## Visual Checks

### Modal Appearance:
- ✓ Black overlay covering entire screen
- ✓ White centered card with rounded corners
- ✓ Warning emoji ⚠️
- ✓ Bold red title
- ✓ Clear consequence text (1,999,999ms penalty)
- ✓ Two prominent buttons

### Mobile Responsive:
- Test on mobile device or resize browser
- ✓ Modal should be readable
- ✓ Buttons stack vertically on small screens
- ✓ Text scales appropriately

## Edge Cases to Test

### 1. Multiple Modal Triggers
- Press back button → Modal shows
- Close modal
- Try Ctrl+R → Modal shows again
- **Expected:** Works correctly each time

### 2. Timer Pause/Resume
- Start game, play for 10 seconds
- Trigger modal
- Note the timer value
- Close and reopen modal a few times
- Resume game
- **Expected:** Timer continues from paused time, not from start

### 3. Rapid Button Clicks
- Trigger modal
- Rapidly click "Exit" multiple times
- **Expected:** Only one forfeit request sent, no errors

## Common Issues & Solutions

### Issue: Modal doesn't appear
**Solution:** Check browser console for JavaScript errors

### Issue: Timer doesn't pause
**Solution:** Verify `pauseTimer()` is being called, check console logs

### Issue: Can still refresh with Ctrl+R
**Solution:** Make sure event.preventDefault() is working, try in different browser

### Issue: Back button goes back instead of showing modal
**Solution:** Check that history.pushState() is being called on connect()

## Browser Compatibility

Test in multiple browsers:
- ✓ Chrome
- ✓ Firefox
- ✓ Safari
- ✓ Edge

**Note:** `beforeunload` message may not show in all browsers (security restriction), but the event still prevents navigation.

## Production Monitoring

After deploying, monitor:
- Forfeit rate (should be low if UI is clear)
- Game completion rate
- Any JavaScript errors in logs
- User feedback about interruptions

---

**Happy Testing!** 🎮
