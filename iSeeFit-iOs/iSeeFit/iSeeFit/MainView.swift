//
//  MainView.swift
//  iSeeFit
//
//  Created by Virginia Zheng on 2025-02-17.
//


import SwiftUI
import SwiftData

struct MainView: View {

    @Environment(\.modelContext) private var modelContext
   @Query private var items: [Item]
   
   @State var text: String = "";
   @State var todos: [String] = [];

   var body: some View {
       VStack{
           Text("Hello, world!")
                             .font(.title)
                             .padding()
           
           HStack{
               TextField("Add a todo!", text: self.$text)
                   .textFieldStyle(RoundedBorderTextFieldStyle())
               
               Button(action:{
                   self.todos.append(self.text);
                   self.text = "";
                   
               }) {
                   Text("Add!")
                       .padding(5)
                       .background(Color.green)
                       .clipShape(RoundedRectangle(cornerRadius: 5))
                       .shadow(color:Color.black.opacity(0.25), radius: 6)
                       .foregroundColor(.white)
               }
           }.padding()
           
           List {
               ForEach(self.todos, id: \.self){ todo in
                   TodoItem(todo:todo)
                       .onLongPressGesture{
                           if let index = todos.firstIndex(of:todo){
                               todos.remove(at: index)
                           }
                       }//Text(todo)
                   //
               }
           }.animation(.spring())
               
       }
       
//        NavigationSplitView {
//            List {
//                ForEach(items) { item in
//                    NavigationLink {
//                        Text("Item at \(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))")
//                    } label: {
//                        Text(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
//                    }
//                }
//                .onDelete(perform: deleteItems)
//            }
//            .toolbar {
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    EditButton()
//                }
//                ToolbarItem {
//                    Button(action: addItem) {
//                        Label("Add Item", systemImage: "plus")
//                    }
//                }
//            }
//        } detail: {
//            Text("Select an item")
//        }
   }

   private func addItem() {
       withAnimation {
           let newItem = Item(timestamp: Date())
           modelContext.insert(newItem)
       }
   }

   private func deleteItems(offsets: IndexSet) {
       withAnimation {
           for index in offsets {
               modelContext.delete(items[index])
           }
       }
   }
}

struct Checkbox: View {
   @Binding var checked: Bool
   var body: some View {
       Button(action: {
           self.checked.toggle()
       }) {
           Image(systemName: self.checked ? "checkmark.circle" : "circle")
               .resizable()
               .foregroundStyle(.green)
       }.buttonStyle(PlainButtonStyle())
   }
}

struct TodoItem: View{
   @State var todo: String = ""
   @State var checked: Bool = false;
   var body: some View {
       HStack {
           Checkbox(checked: $checked)
               .frame(width: 25, height: 26)
           Text(self.todo)
       }
   }
}

// 预览
struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
