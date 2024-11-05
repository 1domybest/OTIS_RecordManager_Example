//
//  AudioView.swift
//  Example
//
//  Created by 온석태 on 10/25/24.
//

import Foundation
import SwiftUI

import CameraManagerFrameWork

struct MultiRecordView: View {
    @ObservedObject var vm: MultiRecordViewModel = MultiRecordViewModel()
    @State var selection:Int = 0
    var body: some View {
        ZStack {
            UIKitViewRepresentable(view: vm.cameraMananger?.multiCameraView)
                .frame(height: (UIScreen.main.bounds.width / 9)  * 16 )
                .overlay(
                    VStack {
                        Spacer().frame(height: 10)
                        HStack {
                            Spacer()
                            
                            Button(action: {
                                self.vm.toggleTorch()
                            }, label: {
                                Text("Torch \(self.vm.isTorchOn ? "OFF" : "ON")")
                                    .foregroundColor(.white)
                                    .bold()
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .foregroundColor(self.vm.isTorchOn ? .black : .red)
                                    )
                            })
                        }
                        
                        Spacer()
                        
                        
                        VStack {
                            Picker(selection: $selection, label: Text("Data")) {
                                ForEach(Array(zip(["video", "photo"], 0...1)), id: \.0) { (name, index) in
                                    Text(name)
                                        .tag(index) // 인덱스를 태그로 설정
                                        .foregroundColor(.yellow)
                                }
                            }
                            .pickerStyle(.wheel)
                            .labelsHidden()
                            .frame(height: 50)
                            .background(Color.black.opacity(0.5))
                            .opacity(self.vm.isRecording ? 0 : 1)
                            .animation(.default, value: self.vm.isRecording)
                            
                            Spacer().frame(height: 10)
                            HStack {
                                Button(action: {
                                    if self.selection == 0 {
                                        if self.vm.isRecording {
                                            self.vm.stopRecording()
                                        } else {
                                            self.vm.startRecording()
                                        }
                                    } else {
                                        if !self.vm.takingPhoto {
                                            self.vm.takePhoto()
                                        }
                                    }
                                   
                                }, label: {
                                    Circle()
                                        .foregroundColor(
                                            self.selection == 1 ? self.vm.takingPhoto ? .black : .white :
                                            self.vm.isRecording ? .blue : .red
                                        )
                                        .animation(.default)
                                        .frame(width: 50, height: 50)
                                })
                                .disabled(self.selection == 1 && self.vm.takingPhoto ? true : false)
                            }
                        }
                        
                        Spacer().frame(height: 20)
                    }
                )
                .overlay(
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            
                            Button(action: {
                                self.vm.changePosition()
                            }, label: {
                                
                                Text("\(self.vm.isFrontMainCamera ? "Back" : "Front")")
                                    .foregroundColor(self.vm.isFrontMainCamera ? .white : .black)
                                    .bold()
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .foregroundColor(self.vm.isFrontMainCamera ? .black : .white)
                                    )
                            })
                            
                            Spacer().frame(width: 10)
                            
                        }
                        
                        Spacer().frame(height: 20)
                    }
                )
        }
        .onDisappear {
            self.vm.unrference()
        }
    }
}
