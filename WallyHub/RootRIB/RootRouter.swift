import RIBs
import SwiftUI

// MARK: - Navigation Protocols

protocol RootRouting: ViewableRouting {
    func routeToAuth()
    func routeToStudent()
    func routeToStudent(student: Student)
    func routeToTeacher()
    func routeToAdmin()
}

protocol RootViewControllable: ViewControllable {
    func present(viewController: ViewControllable)
    func dismiss()
}

final class RootRouter: ViewableRouter<RootInteractable, RootViewControllable>, RootRouting {
    
    private let authBuilder: AuthBuildable
    private let studentBuilder: StudentBuildable
    private let teacherBuilder: TeacherBuildable
    private let adminBuilder: AdminBuildable
    
    private var authRouter: AuthRouting?
    private var studentRouter: StudentRouting?
    private var teacherRouter: TeacherRouting?
    private var adminRouter: AdminRouting?
    
    init(
        interactor: RootInteractable,
        viewController: RootViewControllable,
        authBuilder: AuthBuildable,
        studentBuilder: StudentBuildable,
        teacherBuilder: TeacherBuildable,
        adminBuilder: AdminBuildable
    ) {
        self.authBuilder = authBuilder
        self.studentBuilder = studentBuilder
        self.teacherBuilder = teacherBuilder
        self.adminBuilder = adminBuilder
        super.init(interactor: interactor, viewController: viewController)
        interactor.router = self
    }
    
    func routeToAuth() {
        print("📱 RootRouter.routeToAuth() 호출됨")
        guard authRouter == nil else { 
            print("⚠️ authRouter가 이미 존재함")
            return 
        }
        
        print("🔨 AuthRIB 빌드 시작")
        let authRouter = authBuilder.build(withListener: interactor)
        self.authRouter = authRouter
        attachChild(authRouter)
        
        print("📺 Auth 화면 표시 시작")
        viewController.present(viewController: authRouter.viewControllable)
        print("✅ Auth 화면 표시 완료")
    }
    
    func routeToStudent() {
        print("⚠️ RootRouter: 기본 Student 정보로 StudentRIB 빌드")
        let defaultStudent = Student(name: "기본 학생", studentId: "default", boardId: "")
        routeToStudent(student: defaultStudent)
    }
    
    func routeToStudent(student: Student) {
        print("🔄 RootRouter: routeToStudent() 시작 - Student: \(student.name)")
        
        // 기존 StudentRouter가 있으면 먼저 정리
        if let existingRouter = studentRouter {
            print("🗑️ RootRouter: 기존 StudentRouter 정리 중")
            detachChild(existingRouter)
            studentRouter = nil
            viewController.dismiss()
            print("✅ RootRouter: 기존 StudentRouter 정리 완료")
        }
        
        // 다른 자식들도 정리
        dismissCurrentChild()
        
        print("🎯 RootRouter: Student 정보와 함께 StudentRIB 빌드 - Name: \(student.name)")
        let router = studentBuilder.build(withListener: interactor, student: student)
        print("✅ RootRouter: StudentRIB 빌드 완료")
        
        studentRouter = router
        print("📦 RootRouter: StudentRouter attachChild 시작")
        attachChild(router)
        print("✅ RootRouter: StudentRouter attachChild 완료")
        
        print("📱 RootRouter: StudentViewController present 시작")
        viewController.present(viewController: router.viewControllable)
        print("✅ RootRouter: StudentViewController present 완료")
    }
    
    func routeToTeacher() {
        print("🎯 RootRouter: Teacher 라우팅 시작")
        
        dismissCurrentChild()
        print("✅ RootRouter: dismissCurrentChild 완료")
        
        guard teacherRouter == nil else { 
            print("⚠️ RootRouter: teacherRouter가 이미 존재함, 라우팅 취소")
            return 
        }
        
        print("🔨 RootRouter: TeacherRIB 빌드 시작")
        let router = teacherBuilder.build(withListener: interactor)
        teacherRouter = router
        print("✅ RootRouter: TeacherRIB 빌드 완료")
        
        print("🔗 RootRouter: TeacherRIB attach 시작")
        attachChild(router)
        print("✅ RootRouter: TeacherRIB attach 완료")
        
        print("📺 RootRouter: Teacher 화면 표시 시작")
        viewController.present(viewController: router.viewControllable)
        print("✅ RootRouter: Teacher 화면 표시 완료")
    }
    
    func routeToAdmin() {
        dismissCurrentChild()
        
        guard adminRouter == nil else { return }
        
        let router = adminBuilder.build(withListener: interactor)
        adminRouter = router
        attachChild(router)
        viewController.present(viewController: router.viewControllable)
    }
    
    private func dismissCurrentChild() {
        print("🧹 RootRouter: dismissCurrentChild() 시작")
        
        var childrenCleared = false
        
        if let router = authRouter {
            print("🗑️ RootRouter: AuthRouter 정리 중")
            detachChild(router)
            authRouter = nil
            viewController.dismiss()
            print("✅ RootRouter: AuthRouter 정리 완료")
            childrenCleared = true
        }
        
        if let router = studentRouter {
            print("🗑️ RootRouter: StudentRouter 정리 중")
            detachChild(router)
            studentRouter = nil
            if !childrenCleared {
                viewController.dismiss()
            }
            print("✅ RootRouter: StudentRouter 정리 완료")
            childrenCleared = true
        }
        
        if let router = teacherRouter {
            print("🗑️ RootRouter: TeacherRouter 정리 중")
            detachChild(router)
            teacherRouter = nil
            if !childrenCleared {
                viewController.dismiss()
            }
            print("✅ RootRouter: TeacherRouter 정리 완료")
            childrenCleared = true
        }
        
        if let router = adminRouter {
            print("🗑️ RootRouter: AdminRouter 정리 중")
            detachChild(router)
            adminRouter = nil
            if !childrenCleared {
                viewController.dismiss()
            }
            print("✅ RootRouter: AdminRouter 정리 완료")
            childrenCleared = true
        }
        
        if !childrenCleared {
            print("ℹ️ RootRouter: 정리할 자식 라우터가 없음")
        }
        
        print("✅ RootRouter: dismissCurrentChild() 완료")
    }
}

