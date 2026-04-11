enum FanCommand {
    case help, version, device, report, list, completionZsh, minAll, minFan(Int), maxAll, maxFan(Int), setAllRPM(Int), setFanRPM(Int, Int), autoAll, autoFan(Int)
}
