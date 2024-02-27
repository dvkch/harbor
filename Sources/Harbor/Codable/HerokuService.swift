//
//  HerokuService.swift
//
//
//  Created by syan on 27/02/2024.
//

import Foundation

enum HerokuService: Equatable {
    case app(app: HerokuApp)
    case dyno(app: HerokuApp, dyno: HerokuDyno)
    case db(app: HerokuApp, addon: HerokuAddon)
    
    var app: HerokuApp {
        switch self {
        case .app(let app):     return app
        case .dyno(let app, _): return app
        case .db(let app, _):   return app
        }
    }
}

extension HerokuService: Serviceable {
    var serviceName: String {
        switch self {
        case .app(let app):             return app.name
        case .dyno(let app, let dyno):  return "\(app.name).\(dyno.name)"
        case .db(let app, let addon):   return "\(app.name).\(addon.name)"
        }
    }
    
    var serviceDisplayName: String {
        switch self {
        case .app(let app):             return "\(app.name) (all)"
        case .dyno(let app, let dyno):  return "\(app.name) > \(dyno.name)"
        case .db(let app, let addon):   return "\(app.name) > \(addon.name)"
        }
    }
    
    var serviceNamespace: String {
        fatalError("Unsupported")
    }
    
    var serviceCapabilities: [ServiceCapability] {
        switch self {
        case .app:  return [.reloadable, .exec]
        case .dyno: return [.reloadable, .exec]
        case .db:   return [.db]
        }
    }
}

extension HerokuService: Comparable {
    static func < (lhs: HerokuService, rhs: HerokuService) -> Bool {
        return lhs.serviceDisplayName < rhs.serviceDisplayName
    }
}

extension HerokuService {
    static func services(apps: [HerokuApp], dynos: [HerokuDyno], addons: [HerokuAddon]) -> [HerokuService] {
        var services = [HerokuService]()
        apps.forEach { app in
            services.append(.app(app: app))
            dynos.filter { $0.app.id == app.id }.forEach { dyno in
                services.append(.dyno(app: app, dyno: dyno))
            }
            addons.filter { $0.app.id == app.id }.forEach { addon in
                services.append(.db(app: app, addon: addon))
            }
        }
        return services.sorted()
    }
}
