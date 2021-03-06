//
//  FilterView.swift
//  Popflash
//
//  Created by Seb Vidal on 22/06/2021.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct FilterView: View {
    
    var map: Map
    
    @Binding var selectedType: String
    @Binding var selectedTick: String
    @Binding var selectedSide: String
    @Binding var selectedBind: String
    
    var body: some View {
        
        ScrollView(showsIndicators: false) {
            
            VStack(alignment: .leading, spacing: 8) {
                
                Header()
                
                QuickActions(map: map)
                
                Divider()
                    .padding(.top, 8)
                
                Group {
                    
                    Text("Filter")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding(.leading, 2)
                    
                    Text("Type")
                        .font(.headline)
                        .padding(.leading, 2)
                    
                    SegmentedPicker(items: ["Smoke", "Flashbang", "Molotov", "Grenade"],
                                    defaultsKey: "type",
                                    style: .single,
                                    selectedItems: $selectedType)
                        .padding(.bottom, 8)
                    
                    Text("Tick-Rate")
                        .font(.headline)
                        .padding(.leading, 2)
                    
                    SegmentedPicker(items: ["64", "128"],
                                    defaultsKey: "tick",
                                    style: .single,
                                    selectedItems: $selectedTick)
                        .padding(.bottom, 8)
                    
                    Text("Side")
                        .font(.headline)
                        .padding(.leading, 2)
                    
                    SegmentedPicker(items: ["Terrorist", "Counter-\nTerrorist"],
                                    defaultsKey: "side",
                                    style: .single,
                                    selectedItems: $selectedSide)
                        .padding(.bottom, 8)
                    
                    Text("Jump-Throw Bind")
                        .font(.headline)
                        .padding(.leading, 2)
                    
                    SegmentedPicker(items: ["Yes", "No"],
                                    defaultsKey: "bind",
                                    style: .single,
                                    selectedItems: $selectedBind)
                        .padding(.bottom, 8)
                    
                }
                
            }
            .padding(.horizontal)
            
        }
        
    }
    
}

private struct Header: View {
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        
        HStack(alignment: .center) {
            
            Text("More")
                .font(.title2)
                .fontWeight(.semibold)
            
            Spacer()
            
            Button {
                
                dismiss()
                
            } label: {
                
                Circle()
                    .frame(width: 30, height: 30)
                    .foregroundStyle(Color("Picker_Background"))
                    .overlay(Image(systemName: "multiply").font(.headline).foregroundStyle(Color("Search_Bar_Icons")))
                
            }
            
        }
        .padding(.top, 16)
        .padding(.leading, 2)
        
    }
    
}

private struct QuickActions: View {
    
    var map: Map
    
    @FocusState var searchFocused: Bool
    
    var body: some View {
        
        HStack {
            
            SearchButton()
            
            FavouriteButton(map: map)
            
            OverviewButton(map: map)
            
        }
        .frame(height: 75)
        .padding(.top, 8)
        
    }
    
}

private struct SearchButton: View {
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        
        Button(action: search) {
            
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .foregroundStyle(Color("Picker_Background"))
                .overlay {
                    
                    VStack(spacing: 4) {
                        
                        Image(systemName: "magnifyingglass")
                            .font(.title2)
                        Text("Search")
                            .font(.callout)
                        
                    }
                    
                }
            
        }
        
    }
    
    func search() {
        
        dismiss()
        
    }
    
}

private struct FavouriteButton: View {
    
    var map: Map
    
    @State private var isLoading = true
    @State private var isFavourite = false
    @State private var showingLoginAlert = false
    @State private var showingLoginSheet = false
    
    @AppStorage("favourites.maps") private var favouriteMaps: Array = [String]()
    
    var body: some View {
        
        Button(action: favourite) {
            
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .foregroundStyle(Color("Picker_Background"))
                .overlay {
                    
                    VStack(spacing: 4) {
                        
                        Image(systemName: isFavourite ? "heart.slash.fill" : "heart.fill")
                            .font(.title2)
                        Text(isFavourite ? "Unfavourite" : "Favourite")
                            .font(.callout)
                        
                    }
                    
                }
            
        }
        .onAppear(perform: getFavourite)
        .sheet(isPresented: $showingLoginSheet) {
            
            LoginSheet()
            
        }
        .alert(isPresented: $showingLoginAlert) {
            
            Alert(title: Text("Sign In"),
                  message: Text("Sign in to Popflash to add maps to your favourites."),
                  primaryButton: .default(Text("Sign In"), action: showLogin),
                  secondaryButton: .cancel())
            
        }
        
    }
    
    func getFavourite() {
        
        guard let user = Auth.auth().currentUser else {
            
            return
            
        }
        
        if user.isAnonymous {
            
            isLoading = false
            
            return
            
        }
        
        let db = Firestore.firestore()
        let mapRef = db.collection("maps").document(map.id)
        let ref = db.collection("users").document(user.uid).collection("maps").whereField("map", isEqualTo: mapRef)
        
        ref.getDocuments { snapshot, error in
            
            guard let documents = snapshot?.documents else {
                
                return
                
            }
            
            isFavourite = !documents.isEmpty
            
            DispatchQueue.main.async {
                
                isLoading = false
                
            }
            
        }
        
    }
    
    func favourite() {
        
        if isLoading {
            
            return
            
        }
        
        guard let user = Auth.auth().currentUser else {
            
            return
            
        }
        
        if user.isAnonymous {
            
            showingLoginAlert = true
            
        } else {
            
            if isFavourite {
                
                removeFromFavourites()
                
            } else {
                
                addToFavourites()
                
            }
            
        }
        
    }
    
    func addToFavourites() {
        
        guard let user = Auth.auth().currentUser else {
            
            return
            
        }
        
        if user.isAnonymous {
            
            return
            
        }
        
        isLoading = true
        
        let db = Firestore.firestore()
        let ref = db.collection("users").document(user.uid).collection("maps").document()
        
        guard let dateDouble = Double(dateString(from: Date())) else {
            
            return
            
        }
        
        ref.setData([
            "id": map.id,
            "map": db.collection("maps").document(map.id),
            "position": dateDouble
        ]) { error in
            
            isLoading = false
            
            if let error = error {
                
                print(error.localizedDescription)
                
                return
                
            }
            
            isFavourite = true
            
        }
        
    }
    
    func removeFromFavourites() {
        
        guard let user = Auth.auth().currentUser else {
            
            return
            
        }
        
        if user.isAnonymous {
            
            return
            
        }
        
        isLoading = true
        
        let db = Firestore.firestore()
        let mapRef = db.collection("maps").document(map.id)
        let ref = db.collection("users").document(user.uid).collection("maps").whereField("map", isEqualTo: mapRef)
        
        ref.getDocuments { snapshot, error in
            
            guard let documents = snapshot?.documents else {
                
                return
                
            }
            
            for document in documents {
                
                let favRef = db.collection("users").document(user.uid).collection("maps").document(document.documentID)
                
                favRef.delete { error in
                    
                    if let error = error {
                        
                        print(error.localizedDescription)
                        
                        isLoading = false
                        
                        return
                        
                    }
                    
                    isFavourite = false
                    
                }
                
            }
            
        }
        
    }
    
    func showLogin() {
        
        showingLoginSheet = true
        
    }
    
}

private struct OverviewButton: View {
    
    var map: Map
    
    @State private var isShowing = false
    
    var body: some View {
        
        Button(action: showOverview) {
            
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .foregroundStyle(Color("Picker_Background"))
                .overlay {
                    
                    VStack(spacing: 4) {
                        
                        Image(systemName: "map.fill")
                            .font(.title2)
                        Text("Overview")
                            .font(.callout)
                        
                    }
                    
                }
            
        }
        .sheet(isPresented: $isShowing) {
            
            OverviewView(map: map)
            
        }
        
    }
    
    func showOverview() {
        
        isShowing.toggle()
        
    }
    
}
