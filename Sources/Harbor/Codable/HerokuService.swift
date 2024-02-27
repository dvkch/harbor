//
//  HerokuService.swift
//
//
//  Created by syan on 27/02/2024.
//

import Foundation

struct HerokuService: Equatable {
    let app: HerokuApp
    let dyno: HerokuDyno?
    let addons: [HerokuAddon]
}

extension HerokuService: Serviceable {
    var serviceDisplayName: String {
        if let dyno {
            return "\(app.name).\(dyno.name)"
        }
        return app.name
    }

    var serviceName: String {
        return dyno?.name ?? ""
    }
    
    var serviceNamespace: String {
        return app.name
    }
    
    var serviceCapabilities: [ServiceCapability] {
        var capabilities = [ServiceCapability]()
        capabilities.append(.reloadable)
        if dyno == nil {
            capabilities.append(.exec)
            if addons.contains(where: { $0.addonService.kind == .postgresql }) {
                capabilities.append(.db)
            }
        }
        return capabilities
    }
}

extension HerokuService {
    static func services(apps: [HerokuApp], dynos: [HerokuDyno], addons: [HerokuAddon]) -> [HerokuService] {
        var services = [HerokuService]()
        apps.sorted { $0.name < $1.name }.forEach { app in
            let appAddons = addons.filter { $0.app.id == app.id }
            services.append(.init(app: app, dyno: nil, addons: appAddons))
            dynos.filter { $0.app.id == app.id }.forEach { dyno in
                services.append(.init(app: app, dyno: dyno, addons: appAddons))
            }
        }
        return services
    }
}
