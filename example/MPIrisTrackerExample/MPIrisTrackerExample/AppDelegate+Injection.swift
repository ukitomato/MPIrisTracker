//
//  AppDelegate+Injection.swift
//  ExperimentsApp
//
//  Created by Yuki Yamato on 2021/04/09.
//

import Foundation
import Resolver


extension Resolver: ResolverRegistering {
    public static func registerAllServices() {
        register { IrisTrackController() } .scope(.application)
    }
}
