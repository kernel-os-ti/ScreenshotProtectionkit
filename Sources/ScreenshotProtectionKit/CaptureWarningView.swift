//
//  CaptureWarningView.swift
//  StudioOnze
//
//  Created by Murilo Araujo on 04/08/25.
//  Copyright © 2025 br.com.studioonze. All rights reserved.
//

import SwiftUI

struct CaptureWarningView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image("noprint")
                .resizable()
                .frame(width: 90, height: 90)
                .cornerRadius(24)
                .shadow(radius: 12)

            Text("Opa! Essa tela não pode ser capturada!")
                .multilineTextAlignment(.center)

            Text(
                "Para garantir a melhor qualidade ao compartilhar suas fotos, salve ela no seu dispositivo usando o botão 'Salvar Foto'"
            )
            
            Image("download-demo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .cornerRadius(24)
                .shadow(radius: 8)
                .padding(.horizontal)
        }
        .padding()
        .frame(maxWidth: 1000)
    }
}

#Preview {
    CaptureWarningView()
}
