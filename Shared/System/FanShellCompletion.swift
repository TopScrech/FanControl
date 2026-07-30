enum FanShellCompletion {
    nonisolated static let executableName = "fan"
    nonisolated static let zshFilename = "_fan"
    nonisolated static let managedHeader = "# FanControl zsh completion"

    static func zshScript() -> String {
        #"""
        #compdef \#(executableName)
        \#(managedHeader)

        _fan() {
            local -a commandSpecs
            commandSpecs=(
                'help:Show this help'
                '-h:Show this help'
                '--help:Show this help'
                'list:List all fans'
                '-l:List all fans'
                'min:Set all fans to minimum'
                'max:Set all fans to maximum'
                'auto:Set all fans to auto'
                '-a:Set all fans to auto'
                '-id:Set a specific fan'
                '--id:Set a specific fan'
                '--version:Print app version'
                '-v:Print app version'
                '--device:Print device model'
                '-d:Print device model'
                '--report:Print support report'
                '-r:Print support report'
            )

            local -a fanValueSpecs
            fanValueSpecs=(
                'min:Set one fan to minimum'
                'max:Set one fan to maximum'
                'auto:Set one fan to auto'
                '-a:Set one fan to auto'
                '1000:Set one fan to 1000 RPM'
                '1500:Set one fan to 1500 RPM'
                '2000:Set one fan to 2000 RPM'
                '2500:Set one fan to 2500 RPM'
                '3000:Set one fan to 3000 RPM'
                '3500:Set one fan to 3500 RPM'
                '4000:Set one fan to 4000 RPM'
                '4500:Set one fan to 4500 RPM'
                '5000:Set one fan to 5000 RPM'
                '1.5k:Set one fan to 1500 RPM'
                '2k:Set one fan to 2000 RPM'
                '2.5k:Set one fan to 2500 RPM'
                '3k:Set one fan to 3000 RPM'
                '4k:Set one fan to 4000 RPM'
                '5k:Set one fan to 5000 RPM'
            )

            case $CURRENT in
                2)
                    _describe -t fan-commands 'fan commands' commandSpecs
                    return
                    ;;
                3)
                    if [[ ${words[2]} == -id || ${words[2]} == --id ]]; then
                        _fan_ids
                        return
                    fi
                    ;;
                4)
                    if [[ ${words[2]} == -id || ${words[2]} == --id ]]; then
                        _describe -t fan-values 'fan values' fanValueSpecs
                        return
                    fi
                    ;;
            esac
        }

        _fan_ids() {
            local -a fanIds
            fanIds=(${(f)$(command \#(executableName) list 2>/dev/null | awk 'NR > 1 && $1 ~ /^[0-9]+$/ { print $1 ":" "Fan " $1 }')})

            if (( ${#fanIds[@]} > 0 )); then
                _describe -t fan-ids 'fan ids' fanIds
                return
            fi

            _message 'fan id'
        }

        _fan
        """#
    }
}
