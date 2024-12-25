describe("WakeupMgr", function()
    local RTC
    local WakeupMgr
    local epoch1, epoch2, epoch3

    setup(function()
        require("commonrequire")
        RTC = require("ffi/rtc")
        WakeupMgr = require("device/wakeupmgr"):new{}
        -- We could theoretically test this by running the tests as root locally.
        stub(WakeupMgr, "setWakeupAlarm")
        WakeupMgr.validateWakeupAlarmByProximity = spy.new(function() return true end)

        epoch1 = RTC:secondsFromNowToEpoch(1234)
        epoch2 = RTC:secondsFromNowToEpoch(123)
        epoch3 = RTC:secondsFromNowToEpoch(9999)
    end)

    it("should add a task", function()
        WakeupMgr:addTask(1234, function() end)
        assert.is_equal(epoch1, WakeupMgr._task_queue[1].epoch)
        assert.stub(WakeupMgr.setWakeupAlarm).was.called(1)
    end)
    it("should add a task in order", function()
        WakeupMgr:addTask(9999, function() end)
        assert.is_equal(epoch1, WakeupMgr._task_queue[1].epoch)
        assert.stub(WakeupMgr.setWakeupAlarm).was.called(1)

        WakeupMgr:addTask(123, function() end)
        assert.is_equal(epoch2, WakeupMgr._task_queue[1].epoch)
        assert.stub(WakeupMgr.setWakeupAlarm).was.called(2)
    end)
    it("should execute top task", function()
        assert.is_true(WakeupMgr:wakeupAction())
    end)
    it("should have removed executed task from stack", function()
        assert.is_equal(epoch1, WakeupMgr._task_queue[1].epoch)
        assert.is_equal(epoch3, WakeupMgr._task_queue[2].epoch)
    end)
    it("should have scheduled next task after execution", function()
        assert.stub(WakeupMgr.setWakeupAlarm).was.called(3) -- 2 from addTask (the second addTask doesn't replace the upcoming task), 1 from wakeupAction (via removeTask).
    end)
    it("should remove arbitrary task from stack", function()
        WakeupMgr:removeTask(2)
        assert.is_equal(epoch1, WakeupMgr._task_queue[1].epoch)
        assert.is_equal(nil, WakeupMgr._task_queue[2])
    end)
    it("should execute last task", function()
        assert.is_true(WakeupMgr:wakeupAction())
    end)
    it("should not have scheduled a wakeup without a task", function()
        assert.stub(WakeupMgr.setWakeupAlarm).was.called(3) -- 2 from addTask, 1 from wakeupAction, 0 from removeTask (because it wasn't the upcoming task that was removed)
    end)
end)
